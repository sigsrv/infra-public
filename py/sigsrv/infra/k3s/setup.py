#!/usr/bin/env python3
import code
import os
import shlex
import ssl
import warnings
from builtins import DeprecationWarning
from copy import deepcopy
from dataclasses import dataclass
from functools import cache
from pathlib import Path

import pylxd.exceptions
import pylxd.models
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


@cache
def get_lxd_client(context: Context) -> pylxd.Client:
    return pylxd.Client(
        endpoint="https://sigsrv:8443",
        verify=os.path.join(CERTS_PATH, "servercerts/sigsrv.crt"),
        project=context.LXD_PROJECT_NAME,
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

    tokens = call(context, k3s_master_node, "ip", "-4", "-br", "a", "show", "enp5s0").split()
    host_ip = tokens[2].partition("/")[0]

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
    ] = f"https://{host_ip}:6443"
    local.users[context.K3S_CLUSTER_NAME] = remote_user

    with local_kube_config_path.open("w") as f:
        yaml.safe_dump(local.kube_config, f)


def lxd_k3s_update_kubeconfig(
    lxd_project_name: str,
    k3s_cluster_name: str,
    k3s_cluster_node_name: str,
):
    context = Context(
        LXD_PROJECT_NAME=lxd_project_name,
        K3S_CLUSTER_NAME=k3s_cluster_name,
        K3S_CLUSTER_NODE_NAME=k3s_cluster_node_name,
    )

    configure_kube_config(context)
