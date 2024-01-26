#!/usr/bin/env python3
import os
import shlex
import shutil
import ssl
import subprocess
import warnings
from builtins import DeprecationWarning
from copy import deepcopy
from dataclasses import dataclass
from functools import cache
from pathlib import Path
from typing import Iterator

import pylxd.exceptions
import pylxd.models
import requests
import yaml
from pylxd.client import CERTS_PATH

# TODO: remove this when ws4py is fixed
with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)
    ssl.wrap_socket = ssl.SSLContext().wrap_socket


@dataclass(frozen=True)
class Context:
    LXD_PROJECT_NAME: str
    K3S_CLUSTER_NAME: str
    K3S_CLUSTER_NODE_NAME: str
    K3S_MASTER_NODE_COUNT: int
    K3S_WORKER_NODE_COUNT: int


@cache
def get_lxd_client(context: Context) -> pylxd.Client:
    return pylxd.Client(
        endpoint="https://sigsrv:8443",
        verify=os.path.join(CERTS_PATH, "servercerts/sigsrv.crt"),
        project=context.LXD_PROJECT_NAME,
    )


def shell(context: Context, instance, *args, environment=None):
    client = get_lxd_client(context)
    print(f"{instance.name}:", *args)
    subprocess.check_call(
        [
            shutil.which("lxc") or "/opt/homebrew/bin/lxc",
            "exec",
            "--project",
            client.project,
            instance.name,
            *[f"--env={key}={value}" for key, value in (environment or {}).items()],
            "--",
            *args,
        ]
    )


def call(context: Context, instance, *args, environment=None):
    print(f"{instance.name}:", *args)
    result = instance.execute([*args], environment=environment)
    if result.stderr:
        print(result.stderr)

    if result.exit_code != 0:
        print(result.stdout)
        raise RuntimeError(f"Command failed: {shlex.join(args)} -> {result.exit_code}")

    return result.stdout


def fix_pylxd_bug(node: pylxd.models.Instance):
    node.name, sep, project = node.name.partition("?project=")
    url_params = sep + project
    node.files._endpoint._api_endpoint = node.files._endpoint._api_endpoint.replace(
        url_params, ""
    )


@cache
def get_nodes(context: Context) -> dict[str, pylxd.models.Instance]:
    client = get_lxd_client(context)
    nodes: dict[str, pylxd.models.Instance] = {}
    for node in client.instances.all():
        fix_pylxd_bug(node)
        nodes[node.name] = node

    return nodes


def get_k3s_master_node(context: Context) -> pylxd.models.Instance:
    nodes = get_nodes(context)
    return nodes[f"{context.K3S_CLUSTER_NODE_NAME}-master-0"]


def iter_k3s_master_nodes(
    context: Context, ship_first=False
) -> Iterator[pylxd.models.Instance]:
    nodes = get_nodes(context)
    for i in range(0, context.K3S_MASTER_NODE_COUNT):
        if i == 0 and ship_first:
            continue

        yield nodes[f"{context.K3S_CLUSTER_NODE_NAME}-master-{i}"]


def iter_k3s_worker_nodes(context: Context) -> Iterator[pylxd.models.Instance]:
    nodes = get_nodes(context)
    for i in range(0, context.K3S_WORKER_NODE_COUNT):
        yield nodes[f"{context.K3S_CLUSTER_NODE_NAME}-worker-{i}"]


def iter_k3s_nodes(context: Context, *, ship_first=False):
    yield from iter_k3s_master_nodes(context, ship_first=ship_first)
    yield from iter_k3s_worker_nodes(context)


def get_k3s_install_script():
    with requests.get("https://get.k3s.io") as response:
        response.raise_for_status()
        return response.content


def configure_k3s_install_script(context: Context):
    k3s_install_script = None
    for node in iter_k3s_nodes(context):
        try:
            node.files.get("/root/k3s-install.sh")
        except pylxd.exceptions.NotFound:
            if k3s_install_script is None:
                k3s_install_script = get_k3s_install_script()

            node.files.put("/root/k3s-install.sh", k3s_install_script)
            call(context, node, "chmod", "+x", "/root/k3s-install.sh")


def configure_k3s(context: Context):
    k3s_master_node = get_k3s_master_node(context)

    call(context, k3s_master_node, "mkdir", "-p", "/etc/rancher/k3s")
    k3s_master_node.files.put(
        "/etc/rancher/k3s/config.yaml",
        yaml.dump(
            {
                "cluster-init": True,
                "secrets-encryption": True,
                "flannel-backend": "wireguard-native",
                "node-taint": ["node-role.kubernetes.io/master=true:NoSchedule"],
            }
        ),
    )

    try:
        shell(context, k3s_master_node, "/root/k3s-install.sh", "server")
    except subprocess.CalledProcessError:
        shell(context, k3s_master_node, "journalctl", "-xeu", "k3s.service")
        raise

    k3s_token = call(
        context, k3s_master_node, "cat", "/var/lib/rancher/k3s/server/node-token"
    ).strip()
    for node in iter_k3s_master_nodes(context, ship_first=True):
        call(context, node, "mkdir", "-p", "/etc/rancher/k3s")
        node.files.put(
            "/etc/rancher/k3s/config.yaml",
            yaml.dump(
                {
                    "secrets-encryption": True,
                    "flannel-backend": "wireguard-native",
                    "server": f"https://{context.K3S_CLUSTER_NODE_NAME}-master-0:6443",
                    "node-taint": ["node-role.kubernetes.io/master=true:NoSchedule"],
                }
            ),
        )

        try:
            shell(
                context,
                node,
                "/root/k3s-install.sh",
                "server",
                environment={"K3S_TOKEN": k3s_token},
            )
        except subprocess.CalledProcessError:
            shell(context, node, "journalctl", "-xeu", "k3s.service")
            raise

    for node in iter_k3s_worker_nodes(context):
        call(context, node, "mkdir", "-p", "/etc/rancher/k3s")
        node.files.put(
            "/etc/rancher/k3s/config.yaml",
            yaml.dump(
                {
                    "server": f"https://{context.K3S_CLUSTER_NODE_NAME}-master-0:6443",
                }
            ),
        )

        try:
            shell(
                context,
                node,
                "/root/k3s-install.sh",
                "agent",
                environment={"K3S_TOKEN": k3s_token},
            )
        except subprocess.CalledProcessError:
            shell(context, node, "journalctl", "-xeu", "k3s.service")
            raise


class KubeConfigItems:
    def __init__(self, kube_config: "KubeConfig", section_name: str):
        self.kube_config = kube_config
        self.section_name = section_name

    def __getitem__(self, name):
        for item in self.kube_config.kube_config[self.section_name]:
            if item["name"] == name:
                return item

        raise KeyError(name)

    def __setitem__(self, name, value):
        value = {
            **deepcopy(value),
            "name": name,
        }

        for item in self.kube_config.kube_config[self.section_name]:
            if item["name"] == name:
                item.update(value)
                return

        self.kube_config.kube_config[self.section_name].append(value)

    def __delitem__(self, name):
        for i, item in enumerate(self.kube_config.kube_config[self.section_name]):
            if item["name"] == name:
                del self.kube_config.kube_config[self.section_name][i]
                return

        raise KeyError(name)

    def __contains__(self, item):
        try:
            self.kube_config.kube_config[self.section_name]  # noqa
            return True
        except KeyError:
            return False


class KubeConfig:
    def __init__(self, kube_config: dict):
        self.kube_config = kube_config
        self.clusters = KubeConfigItems(self, "clusters")
        self.contexts = KubeConfigItems(self, "contexts")
        self.users = KubeConfigItems(self, "users")

    @property
    def current_context_name(self):
        return self.kube_config["current-context"]


def configure_kube_config(context: Context):
    k3s_master_node = get_k3s_master_node(context)
    remote = KubeConfig(
        yaml.safe_load(
            call(context, k3s_master_node, "cat", "/etc/rancher/k3s/k3s.yaml")
        )
    )

    local_kube_config_path = Path("~/.kube/config").expanduser()
    with local_kube_config_path.open("r") as f:
        local = KubeConfig(yaml.safe_load(f))

    remote_context = remote.contexts[remote.current_context_name]
    remote_cluster = remote.clusters[remote_context["context"]["cluster"]]
    remote_user = remote.users[remote_context["context"]["user"]]

    local.contexts[context.K3S_CLUSTER_NAME] = {
        "context": {
            "cluster": context.K3S_CLUSTER_NAME,
            "user": context.K3S_CLUSTER_NAME,
        }
    }
    local.clusters[context.K3S_CLUSTER_NAME] = remote_cluster
    local.clusters[context.K3S_CLUSTER_NAME]["cluster"][
        "server"
    ] = f"https://{context.K3S_CLUSTER_NODE_NAME}-master-0:6443"
    local.users[context.K3S_CLUSTER_NAME] = remote_user

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local.kube_config, f)


def configure_registries(context):
    for node in iter_k3s_master_nodes(context):
        node.files.put(
            "/etc/rancher/k3s/registries.yaml",
            yaml.dump(
                {
                    "mirrors": {
                        f"{context.K3S_CLUSTER_NAME}.deer-neon.ts.net": {
                            "endpoint": [
                                f"https://{context.K3S_CLUSTER_NAME}.deer-neon.ts.net"
                            ]
                        }
                    }
                }
            ),
        )


def setup_k3s(
    lxd_project_name: str,
    k3s_cluster_name: str,
    k3s_cluster_node_name: str,
    k3s_master_node_count: int,
    k3s_worker_node_count: int,
):
    context = Context(
        LXD_PROJECT_NAME=lxd_project_name,
        K3S_CLUSTER_NAME=k3s_cluster_name,
        K3S_CLUSTER_NODE_NAME=k3s_cluster_node_name,
        K3S_MASTER_NODE_COUNT=k3s_master_node_count,
        K3S_WORKER_NODE_COUNT=k3s_worker_node_count,
    )

    configure_k3s_install_script(context)
    configure_k3s(context)
    configure_kube_config(context)
    configure_registries(context)


def main():
    setup_k3s(
        lxd_project_name="sigsrv-sdlc",
        k3s_cluster_node_name="sigsrv-sdlc-k3s",
        k3s_cluster_name="sigsrv-sdlc",
        k3s_master_node_count=3,
        k3s_worker_node_count=5,
    )


if __name__ == "__main__":
    main()
