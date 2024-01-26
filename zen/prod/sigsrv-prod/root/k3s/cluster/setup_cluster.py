#!/usr/bin/env python3
import sys
from pathlib import Path

for parent in Path(__file__).parents:
    if (parent / ".git").exists():
        sys.path.append(str((parent / "py").resolve()))


def main():
    from sigsrv.infra.k3s.setup import setup_k3s

    setup_k3s(
        lxd_project_name="sigsrv-prod",
        k3s_cluster_node_name="sigsrv-prod-k3s",
        k3s_cluster_name="sigsrv-prod",
        k3s_master_node_count=3,
        k3s_worker_node_count=5,
    )


if __name__ == "__main__":
    main()
