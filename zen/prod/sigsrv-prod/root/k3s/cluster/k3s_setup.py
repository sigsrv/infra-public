#!/usr/bin/env python3
import os
import shlex
import shutil
import ssl
import subprocess
import warnings
from builtins import DeprecationWarning
from copy import deepcopy
from pathlib import Path
from typing import Iterator

import pylxd.exceptions
import pylxd.models
import requests
import yaml
from pylxd.client import CERTS_PATH

LXD_PROJECT_NAME = "sigsrv-prod"
K3S_CLUSTER_NODE_NAME = "sigsrv-prod-k3s"
K3S_CLUSTER_NAME = "sigsrv-prod"

# TODO: remove this when ws4py is fixed
with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)
    ssl.wrap_socket = ssl.SSLContext().wrap_socket

client = pylxd.Client(
    endpoint="https://sigsrv:8443",
    verify=os.path.join(CERTS_PATH, "servercerts/sigsrv.crt"),
    project=LXD_PROJECT_NAME,
)


def shell(instance, *args, environment=None):
    print(f"{instance.name}:", *args)
    subprocess.check_call(
        [
            shutil.which("lxc") or "/opt/homebrew/bin/lxc",
            "exec",
            "--project",
            client.project,
            instance.name,
            *[
                f"--env={key}={value}"
                for key, value in (environment or {}).items()
            ],
            "--",
            *args,
        ]
    )


def call(instance, *args, environment=None):
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
    node.files._endpoint._api_endpoint = node.files._endpoint._api_endpoint.replace(url_params, "")


NODES: dict[str, pylxd.models.Instance] = {}
for node in client.instances.all():
    fix_pylxd_bug(node)
    NODES[node.name] = node


def get_k3s_master_node() -> pylxd.models.Instance:
    return NODES[f"{K3S_CLUSTER_NODE_NAME}-master-0"]


def iter_k3s_master_nodes(ship_first=False) -> Iterator[pylxd.models.Instance]:
    for i in range(0, 3):
        if i == 0 and ship_first:
            continue

        yield NODES[f"{K3S_CLUSTER_NODE_NAME}-master-{i}"]


def iter_k3s_worker_nodes() -> Iterator[pylxd.models.Instance]:
    for i in range(0, 5):
        yield NODES[f"{K3S_CLUSTER_NODE_NAME}-worker-{i}"]


def iter_k3s_nodes(*, ship_first=False):
    yield from iter_k3s_master_nodes(ship_first=ship_first)
    yield from iter_k3s_worker_nodes()


def get_k3s_install_script():
    with requests.get("https://get.k3s.io") as response:
        response.raise_for_status()
        return response.content


def configure_k3s_install_script():
    k3s_install_script = None
    for node in iter_k3s_nodes():
        try:
            node.files.get("/root/k3s-install.sh")
        except pylxd.exceptions.NotFound:
            if k3s_install_script is None:
                k3s_install_script = get_k3s_install_script()

            node.files.put("/root/k3s-install.sh", k3s_install_script)
            call(node, "chmod", "+x", "/root/k3s-install.sh")


def configure_k3s():
    k3s_master_node = get_k3s_master_node()

    call(k3s_master_node, "mkdir", "-p", "/etc/rancher/k3s")
    k3s_master_node.files.put("/etc/rancher/k3s/config.yaml", yaml.dump(
        {
            "cluster-init": True,
            "secrets-encryption": True,
            "flannel-backend": "wireguard-native",
            "node-taint": ["node-role.kubernetes.io/master=true:NoSchedule"],
        }
    ))

    try:
        shell(k3s_master_node, "/root/k3s-install.sh", "server")
    except subprocess.CalledProcessError:
        shell(k3s_master_node, "journalctl", "-xeu", "k3s.service")
        raise

    k3s_token = call(k3s_master_node, "cat", "/var/lib/rancher/k3s/server/node-token").strip()
    for node in iter_k3s_master_nodes(ship_first=True):
        call(node, "mkdir", "-p", "/etc/rancher/k3s")
        node.files.put(
            "/etc/rancher/k3s/config.yaml",
            yaml.dump(
                {
                    "secrets-encryption": True,
                    "flannel-backend": "wireguard-native",
                    "server": f"https://{K3S_CLUSTER_NODE_NAME}-master-0:6443",
                    "node-taint": ["node-role.kubernetes.io/master=true:NoSchedule"],
                }
            )
        )

        try:
            shell(node, "/root/k3s-install.sh", "server", environment={"K3S_TOKEN": k3s_token})
        except subprocess.CalledProcessError:
            shell(node, "journalctl", "-xeu", "k3s.service")
            raise

    for node in iter_k3s_worker_nodes():
        call(node, "mkdir", "-p", "/etc/rancher/k3s")
        node.files.put(
            "/etc/rancher/k3s/config.yaml",
            yaml.dump(
                {
                    "server": f"https://{K3S_CLUSTER_NODE_NAME}-master-0:6443",
                }
            )
        )

        try:
            shell(node, "/root/k3s-install.sh", "agent", environment={"K3S_TOKEN": k3s_token})
        except subprocess.CalledProcessError:
            shell(node, "journalctl", "-xeu", "k3s.service")
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


def configure_kube_config():
    k3s_master_node = get_k3s_master_node()
    remote = KubeConfig(
        yaml.safe_load(
            call(k3s_master_node, "cat", "/etc/rancher/k3s/k3s.yaml")
        )
    )

    local_kube_config_path = Path("~/.kube/config").expanduser()
    with local_kube_config_path.open("r") as f:
        local = KubeConfig(yaml.safe_load(f))

    remote_context = remote.contexts[remote.current_context_name]
    remote_cluster = remote.clusters[remote_context["context"]["cluster"]]
    remote_user = remote.users[remote_context["context"]["user"]]

    local.contexts[K3S_CLUSTER_NAME] = {
        "context": {
            "cluster": K3S_CLUSTER_NAME,
            "user": K3S_CLUSTER_NAME,
        }
    }
    local.clusters[K3S_CLUSTER_NAME] = remote_cluster
    local.clusters[K3S_CLUSTER_NAME]["cluster"][
        "server"] = f"https://{K3S_CLUSTER_NODE_NAME}-master-0:6443"
    local.users[K3S_CLUSTER_NAME] = remote_user

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local.kube_config, f)


def configure_registries():
    for node in iter_k3s_master_nodes():
        node.files.put("/etc/rancher/k3s/registries.yaml", yaml.dump(
            {
                "mirrors": {
                    f"{K3S_CLUSTER_NAME}.deer-neon.ts.net": {
                        "endpoint": [f"https://{K3S_CLUSTER_NAME}.deer-neon.ts.net"]
                    }
                }
            }
        ))


def main():
    configure_k3s_install_script()
    configure_k3s()
    configure_kube_config()
    configure_registries()


if __name__ == "__main__":
    main()
