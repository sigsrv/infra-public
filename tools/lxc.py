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
            for command in ["shell"]:
                if command in argv[:pos]:
                    idx = argv.index(command) + 1
                    break
            else:
                idx = 1

            argv[idx:idx] += ["--project", lxc_project]
            pos += 2

    if "list" in argv[:pos] and "device" not in argv[:pos]:
        argv[1:1] += ["--format", "compact"]
        pos += 2

    os.execl(shutil.which("lxc"), *argv)


if __name__ == "__main__":
    main()
