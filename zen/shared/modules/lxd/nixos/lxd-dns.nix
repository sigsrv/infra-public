{ lib, config, pkgs, ... }: {
  networking.nameservers = [
    "${lxd_dns_server_0}"
    "${lxd_dns_server_1}"
  ];
  networking.search = [ "${lxd_dns_domain}" ];
}
