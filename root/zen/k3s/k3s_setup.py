#!/usr/bin/env python3
import os
import shutil
import ssl
import subprocess
import warnings
from builtins import DeprecationWarning
from copy import deepcopy
from pathlib import Path
import shlex

from typing import Literal, Iterator

import pylxd.models
import requests
import yaml
from pylxd.client import CERTS_PATH

# TODO: remove this when ws4py is fixed
with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)
    ssl.wrap_socket = ssl.SSLContext().wrap_socket


client = pylxd.Client(
    endpoint="https://sigsrv:8443",
    verify=os.path.join(CERTS_PATH, "servercerts/sigsrv.crt"),
    project="sigsrv-k3s",
)


def shell(instance, *args):
    print(f"{instance.name}:", *args)
    subprocess.check_call(
        [
            shutil.which("lxc") or "/opt/homebrew/bin/lxc",
            "exec",
            "--project",
            client.project,
            instance.name,
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
    return NODES["sigsrv-k3s-master-0"]


def iter_k3s_master_nodes(ship_first=False) -> Iterator[pylxd.models.Instance]:
    for i in range(0, 3):
        if i == 0 and ship_first:
            continue

        yield NODES[f"sigsrv-k3s-master-{i}"]


def iter_k3s_worker_nodes() -> Iterator[pylxd.models.Instance]:
    for i in range(0, 5):
        yield NODES[f"sigsrv-k3s-worker-{i}"]

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
    call(
        k3s_master_node,
        "/root/k3s-install.sh",
        "server",
        "--cluster-init",
        "--secrets-encryption",
        "--flannel-backend=wireguard-native",
        "--node-taint",
        "node-role.kubernetes.io/master=true:NoSchedule",
    )

    k3s_token = call(k3s_master_node, "cat", "/var/lib/rancher/k3s/server/node-token").strip()
    for node in iter_k3s_master_nodes(ship_first=True):
        call(
            node,
            "/root/k3s-install.sh",
            "server",
            "--secrets-encryption",
            "--flannel-backend=wireguard-native",
            "--server",
            "https://sigsrv-k3s-master-0.k3s.sigsrv.local:6443",
            "--node-taint",
            "node-role.kubernetes.io/master=true:NoSchedule",
            environment={
                "K3S_TOKEN": k3s_token,
            }
        )

    for node in iter_k3s_worker_nodes():
        # try:
        #     call(
        #         node,
        #         "/usr/local/bin/k3s-uninstall.sh"
        #     )
        # except RuntimeError:
        #     pass

        call(
            node,
            "/root/k3s-install.sh",
            "agent",
            "--server",
            "https://sigsrv-k3s-master-0.k3s.sigsrv.local:6443",
            environment={
                "K3S_TOKEN": k3s_token,
            }
        )


def configure_tailscale(mode: Literal["init", "up", "down"]):
    for node in iter_k3s_nodes():
        if mode == "init":
            call(node, "sh", "-c", "curl -fsSL https://tailscale.com/install.sh | sh")
            call(node, "sh", "-c", (
                "echo 'net.ipv4.ip_forward = 1'"
                " | sudo tee -a /etc/sysctl.d/99-tailscale.conf"
                " && echo 'net.ipv6.conf.all.forwarding = 1'"
                " | sudo tee -a /etc/sysctl.d/99-tailscale.conf"
                " && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf"
            ))

            # try:
            #     sysctl_conf = node.files.get("/etc/sysctl.d/99-tailscale.conf")
            # except pylxd.exceptions.NotFound:

            for line in [
                b"net.ipv4.ip_forward = 1",
                b"net.ipv6.conf.all.forwarding = 1",
            ]:
                pass  # if line not in sysctl_conf:

            call(node,
                 "tailscale",
                 "up",
                 "--authkey=${var.ts_authkey}",
                 "--ssh",
                 "--advertise-tags=tag:local-sigsrv-k3s-master"
             )
        elif mode == "up":
            try:
                call(node, "tailscale", "status")
            except RuntimeError:
                shell(node, "tailscale", "up")
        elif mode == "down":
            shell(node, "tailscale", "down")


def configure_addons():
    addons = [
        # core default
        # "dns",
        # "ha-cluster",
        # "helm",
        # "helm3",
        # core
        "cert-manager",
        "dashboard",
        "ingress",
        "metrics-server",
        "observability",
        "rbac",
        # "registry",
        # community
        # "community",
        "argocd",
        "istio",
        "jaeger",
        "knative",
    ]

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

    local.contexts["k3s"] = {
        "context": {
            "cluster": "k3s",
            "user": "k3s",
        }
    }
    local.clusters["k3s"] = remote_cluster
    local.clusters["k3s"]["cluster"]["server"] = "https://sigsrv-k3s-master-0.k3s.sigsrv.local:6443"
    local.users["k3s"] = remote_user

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local.kube_config, f)


def configure_volumes():
    k3s_master_node = get_k3s_master_node()
    call(k3s_master_node, "stat", "/mnt/volumes")
    call(k3s_master_node, "mountpoint", "/mnt/volumes")
    call(k3s_master_node, "touch", "/mnt/volumes/mounted")


def main():
    configure_k3s_install_script()
    configure_k3s()
    configure_kube_config()
    # configure_tailscale("up")
    configure_addons()
    configure_volumes()


if __name__ == "__main__":
    main()
