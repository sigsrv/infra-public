{ lib, config, pkgs, ... }: {
  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
  };

  fileSystems."/var/lib/rancher/k3s/storage" = {
    depends = ["/data"];
    device = "/data/k3s-storage";
    fsType = "none";
    options = ["bind"];
  };
}
