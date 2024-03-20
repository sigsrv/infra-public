{ lib, config, pkgs, ... }: {
  services.k3s = {
    enable = true;
    role = "${k3s_role}";
    tokenFile = "${k3s_token_file}";
    configPath = "${k3s_config_path}";
  };

  # https://docs.k3s.io/installation/requirements#inbound-rules-for-k3s-nodes
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2379 2380 6443 10250 ];
    allowedUDPPorts = [ 51820 51821 ];
  };
}
