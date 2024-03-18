#!/usr/bin/env fish
set NIXOS_ARCHITECTURE amd64
set NIXOS_RELEASE unstable
set NIXOS_VARIANT default

set LXD_JENKINS_URL "https://jenkins.linuxcontainers.org"
set LXD_NIXOS_JOB_PATH "job/image-nixos/lastStableBuild"
set LXD_NIXOS_ATTRIBUTES "architecture=$NIXOS_ARCHITECTURE,release=$NIXOS_RELEASE,variant=$NIXOS_VARIANT"
set LXD_NIXOS_ARTIFACT_URL "$LXD_JENKINS_URL/$LXD_NIXOS_JOB_PATH/$LXD_NIXOS_ATTRIBUTES/artifact"

wget -N --no-if-modified-since $LXD_NIXOS_ARTIFACT_URL/incus.tar.xz
wget -N --no-if-modified-since $LXD_NIXOS_ARTIFACT_URL/rootfs.tar.xz
wget -N --no-if-modified-since $LXD_NIXOS_ARTIFACT_URL/disk.qcow2

lxc image import --alias nixos-$NIXOS_RELEASE-container incus.tar.xz rootfs.tar.xz
lxc image import --alias nixos-$NIXOS_RELEASE-vm incus.tar.xz disk.qcow2
