#!/usr/bin/env python3
import sys
from pathlib import Path

for parent in Path(__file__).parents:
    if (parent / ".git").exists():
        sys.path.append(str((parent / "py").resolve()))


def main():
    from sigsrv.infra.k3s.setup import lxd_k3s_update_kubeconfig

    lxd_k3s_update_kubeconfig(
        lxd_project_name="sigsrv-prod",
        k3s_cluster_node_name="sigsrv-prod-k3s",
        k3s_cluster_name="sigsrv-prod",
    )


if __name__ == "__main__":
    main()
