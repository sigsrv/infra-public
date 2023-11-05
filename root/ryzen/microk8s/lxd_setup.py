#!/usr/bin/env python3
import json
import os
import shutil
import ssl
import subprocess
import warnings
from builtins import DeprecationWarning
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse, urlunparse

import pylxd.models
import yaml
from pylxd.client import CERTS_PATH

# TODO: remove this when ws4py is fixed
with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)
    ssl.wrap_socket = ssl.SSLContext().wrap_socket


client = pylxd.Client(
    endpoint="https://sigsrv:8443",
    verify=os.path.join(CERTS_PATH, "servercerts/sigsrv.crt"),
    project="microk8s",
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


def call(instance, *args):
    print(f"{instance.name}:", *args)
    result = instance.execute([*args])
    if result.exit_code != 0:
        raise RuntimeError(f"Command failed: {args} -> {result.exit_code}")

    if result.stderr:
        print(result.stderr)

    return result.stdout


NODES: dict[str, pylxd.models.Instance] = {}
for node in client.instances.all():
    node.name = node.name.partition("?")[0]  # XXX: fix pylxd bug
    NODES[node.name] = node


def get_microk8s_master_node():
    return NODES["microk8s-master-0"]


def iter_microk8s_master_nodes(ship_first=False):
    for i in range(0, 3):
        if i == 0 and ship_first:
            continue

        yield NODES[f"microk8s-master-{i}"]


def iter_microk8s_worker_nodes():
    for i in range(0, 3):
        yield NODES[f"microk8s-worker-{i}"]


def iter_microk8s_nodes(*, ship_first=False):
    yield from iter_microk8s_master_nodes(ship_first=ship_first)
    yield from iter_microk8s_worker_nodes()


def configure_ssh():
    resolved = {
        node.name: address["address"]
        for node in NODES.values()
        for network_id, network in node.state().network.items()
        for address in network["addresses"]
        if address["family"] == "inet" and address["scope"] == "global"
        if address["address"].startswith("100.")
    }

    with Path("~/.ssh/config.d/lxc_ssh").expanduser().open("w") as f:
        for host, address in resolved.items():
            f.write(f"Host {host}\n")
            # f.write(f"    HostName {address}\n")
            f.write(f"    User ubuntu\n")
            f.write(f"\n")


def get_microk8s_join_node_url():
    microk8s_master_node = get_microk8s_master_node()
    data = json.loads(
        call(microk8s_master_node, "microk8s", "add-node", "--format=json")
    )
    for url in data["urls"]:
        if url.startswith("10.100."):
            return url

    raise RuntimeError("No 10.100.*.* address found")


def _configure_node_ha(
    node: pylxd.models.Instance,
    role: Literal["controlplane", "worker"],
    node_joined_message: str,
):
    node_microk8s_status = call(node, "microk8s", "status")
    if node_joined_message in node_microk8s_status:
        return

    url = get_microk8s_join_node_url()
    shell(
        node,
        "microk8s",
        "join",
        url,
        *{"controlplane": [], "worker": ["--worker"]}[role],
    )


def configure_master_ha(node: pylxd.models.Instance):
    _configure_node_ha(
        node,
        "controlplane",
        "high-availability: yes",
    )


def configure_worker_ha(node: pylxd.models.Instance):
    _configure_node_ha(
        node,
        "worker",
        "This MicroK8s deployment is acting as a node in a cluster.",
    )


def configure_ha():
    for node in iter_microk8s_master_nodes(ship_first=True):
        configure_master_ha(node)

    for node in iter_microk8s_worker_nodes():
        configure_worker_ha(node)


def configure_cert_dns():
    for node in iter_microk8s_master_nodes():
        csr_conf_template = "/var/snap/microk8s/current/certs/csr.conf.template"
        dns_line = f"DNS.6 = {node.name}"

        if dns_line not in call(node, "cat", csr_conf_template):
            shell(
                node,
                "sed",
                "-i",
                rf"s/#MOREIPS/&\n{dns_line}/",
                csr_conf_template,
            )

            shell(node, "microk8s", "refresh-certs", "--cert", "server.crt")


def configure_tailscale(mode: Literal["up", "down"]):
    for node in iter_microk8s_nodes():
        if mode == "up":
            try:
                call(node, "tailscale", "status")
            except RuntimeError:
                shell(node, "tailscale", "up")
        else:
            shell(node, "tailscale", "down")


def configure_addons():
    addons = [
        # core default
        "dns",
        "ha-cluster",
        "helm",
        "helm3",
        # core
        "cert-manager",
        "dashboard",
        "hostpath-storage",
        "ingress",
        "metrics-server",
        "observability",
        "rbac",
        "registry",
        # community
        "community",
        "argocd",
        "istio",
        "jaeger",
    ]

    microk8s_master_node = get_microk8s_master_node()
    for addon in addons:
        shell(microk8s_master_node, "microk8s", "enable", addon)


def configure_kube_config():
    microk8s_master_node = get_microk8s_master_node()
    remote_kube_config = yaml.safe_load(
        call(microk8s_master_node, "microk8s", "config")
    )

    local_kube_config_path = Path("~/.kube/config").expanduser()
    with local_kube_config_path.open("r") as f:
        local_kube_config = yaml.safe_load(f)

    context = next(
        context
        for context in remote_kube_config["contexts"]
        if context["name"] == "microk8s"
    )

    context_cluster_name = context["context"]["cluster"]
    context_user_name = context["context"]["user"]

    remote_cluster = remote_kube_config["clusters"][0]
    remote_cluster_server = urlparse(remote_cluster["cluster"]["server"])
    remote_cluster_server_netloc = (
        f"{microk8s_master_node.name}:{remote_cluster_server.port}"
    )
    remote_cluster["cluster"]["server"] = urlunparse(
        remote_cluster_server._replace(netloc=remote_cluster_server_netloc)  # noqa
    )
    for pos, cluster in enumerate(local_kube_config["clusters"]):
        if cluster["name"] == context_cluster_name:
            local_kube_config["clusters"][pos] = remote_cluster
            break

    remote_user = remote_kube_config["users"][0]
    for pos, user in enumerate(local_kube_config["users"]):
        if user["name"] == context_user_name:
            local_kube_config["users"][pos] = remote_user
            break

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local_kube_config, f)


def configure_kube_taint():
    microk8s_master_node = get_microk8s_master_node()
    for node in iter_microk8s_master_nodes():
        call(
            microk8s_master_node,
            "microk8s",
            "kubectl",
            "taint",
            "nodes",
            node.name,
            "node-role.kubernetes.io/master=true:NoSchedule",
            "--overwrite",
        )


def main():
    configure_ssh()
    configure_ha()
    configure_kube_config()
    configure_kube_taint()
    configure_cert_dns()
    configure_tailscale("up")
    configure_addons()


if __name__ == "__main__":
    main()
