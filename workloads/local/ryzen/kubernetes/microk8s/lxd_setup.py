#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

import yaml


def call_json(host, *args):
    print(*["lxc", "exec", "--project", "microk8s", host, "--", *args])
    return json.loads(
        subprocess.check_output(
            ["lxc", "exec", "--project", "microk8s", host, "--", *args]
        )
    )


def call_yaml(host, *args):
    print(*["lxc", "exec", "--project", "microk8s", host, "--", *args])
    return yaml.safe_load(
        subprocess.check_output(
            ["lxc", "exec", "--project", "microk8s", host, "--", *args]
        )
    )


def shell(host, *args):
    print(*["lxc", "exec", "--project", "microk8s", host, "--", *args])
    subprocess.check_call(["lxc", "exec", "--project", "microk8s", host, "--", *args])


def configure_ssh():
    data = json.loads(
        subprocess.check_output(["lxc", "list", "--project", "microk8s", "-f", "json"])
    )

    resolved = {}
    for container in data:
        for network_id, network in container["state"]["network"].items():
            for address in network["addresses"]:
                if address["family"] == "inet" and address["scope"] == "global":
                    if address["address"].startswith("100."):
                        resolved[container["name"]] = address["address"]

    with Path("~/.ssh/config.d/lxc_ssh").expanduser().open("w") as f:
        for host, address in resolved.items():
            f.write(f"Host {host}\n")
            # f.write(f"    HostName {address}\n")
            f.write(f"    User ubuntu\n")
            f.write(f"\n")


def get_microk8s_join_node_url():
    data = call_json("microk8s-master-0", "microk8s", "add-node", "--format=json")
    for url in data["urls"]:
        if url.startswith("10.100."):
            return url

    raise RuntimeError("No 10.100.*.* address found")


def iter_microk8s_master_nodes(ship_first=False):
    for i in range(0, 3):
        if i == 0 and ship_first:
            continue

        yield f"microk8s-master-{i}"


def iter_microk8s_worker_nodes():
    for i in range(0, 3):
        yield f"microk8s-worker-{i}"


def iter_microk8s_nodes(*, ship_first=False):
    yield from iter_microk8s_master_nodes(ship_first=ship_first)
    yield from iter_microk8s_worker_nodes()


def configure_ha():
    for node in iter_microk8s_master_nodes(ship_first=True):
        url = get_microk8s_join_node_url()
        shell(node, "microk8s", "join", url)

    for node in iter_microk8s_worker_nodes():
        url = get_microk8s_join_node_url()
        shell(node, "microk8s", "join", url, "--worker")


def configure_cert_dns():
    for node in iter_microk8s_worker_nodes():
        shell(
            node,
            "sed",
            "-i",
            rf"s/#MOREIPS/&\nDNS.6 = {node}/",
            "/var/snap/microk8s/current/certs/csr.conf.template",
        )

        shell(node, "microk8s", "refresh-certs", "--cert", "server.crt")


def configure_tailscale():
    for node in iter_microk8s_nodes():
        shell(node, "tailscale", "up")


def configure_addons():
    addons = [
        # "cert-manager",
        "dashboard",
        "hostpath-storage",
        "ingress",
        "metrics-server",
        "observability",
        "rbac",
        "registry",
    ]
    shell("microk8s-master-0", "microk8s", "enable", *addons)


def configure_kube_config():
    remote_kube_config = call_yaml("microk8s-master-0", "microk8s", "config")

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

    for pos, cluster in enumerate(local_kube_config["clusters"]):
        if cluster["name"] == context_cluster_name:
            local_kube_config["clusters"][pos] = remote_kube_config["clusters"][0]
            break

    for pos, user in enumerate(local_kube_config["users"]):
        if user["name"] == context_user_name:
            local_kube_config["users"][pos] = remote_kube_config["users"][0]
            break

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local_kube_config, f)


def main():
    # configure_ssh()
    # configure_ha()
    # configure_cert_dns()
    # configure_tailscale()
    configure_addons()
    # configure_kube_config()


if __name__ == "__main__":
    main()
