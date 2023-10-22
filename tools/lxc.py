#!/usr/bin/env python3
import os
import shutil
import sys


def main():
    argv = sys.argv[:]
    argv[0] = "lxc"

    if "--" in argv:
        pos = argv.index("--")
    else:
        pos = len(argv)

    if "--project" not in argv[:pos]:
        if lxc_project := os.getenv("LXC_PROJECT"):
            argv[1:1] += ["--project", lxc_project]

    if "list" in argv[:pos]:
        argv[1:1] += ["--format", "compact"]

    os.execl(shutil.which("lxc"), *argv)


if __name__ == "__main__":
    main()
