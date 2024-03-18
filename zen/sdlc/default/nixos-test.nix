{ lib, config, pkgs, ... }: {
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    fzf
  ];

  networking.firewall.allowedTCPPorts = [
    6443
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
}
