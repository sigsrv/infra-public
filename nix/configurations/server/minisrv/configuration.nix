# /etc/nixos/configuration.nix
# nixos-help command or https://search.nixos.org/options

{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.11"; # Did you read the comment?

  imports = [
    ./hardware-configuration.nix
  ];

  # host
  networking.hostName = "minisrv";
  networking.hostId = "c2947c63"; # zfs

  # zfs
  services.zfs.autoScrub.enable = true;

  # boot
  boot.kernelParams = [
    "zfs.zfs_arc_max=8589934592" # 8 GB
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/cd73c123-49e0-4293-93e3-c28a76fbcafa";
      preLVM = true;
      allowDiscards = true;
    };
  };

  # users
  users.users.ecmaxp = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
  };

  # locale
  i18n.defaultLocale = "en_US.UTF-8";

  # environment
  environment.variables = {
    EDITOR = "micro";
  };

  # networking
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  networking.timeServers = [ "time.cloudflare.com" ];
  networking.interfaces = { };
  networking.vlans = {
    "enp3s0.3" = {
      id = 3;
      interface = "enp3s0";
    };
  };
  networking.dhcpcd = {
    denyInterfaces = [
      "veth*"
      "mac*"
    ];
    extraConfig = ''
      interface enp3s0
      metric 1000
    '';
  };
  networking.nftables.enable = true;
  networking.firewall =
    let
      internalInterfaces = "${lib.concatStringsSep ", " (
        map (x: ''"${x}"'') [
          "enp3s0.3"
          "incusbr0"
          "incusbr1"
          "userbr0"
          "userbr1"
        ]
      )}";
      externalInterfaces = "${lib.concatStringsSep ", " (
        map (x: ''"${x}"'') [
          "enp3s0"
        ]
      )}";
    in
    rec {
      enable = true;
      allowedUDPPorts = [ 41641 ];
      trustedInterfaces = [ "tailscale0" ];
      interfaces = {
        "enp3s0.3" = {
          allowedTCPPorts = config.services.openssh.ports;
        };
        "tailscale0" = {
          allowedTCPPorts = [
            6443
            8443
          ];
        };
        # incus
        "incusbr0" = {
          allowedUDPPorts = [
            53
            67
            1900
            5351
          ];
        };
        "incusbr1" = interfaces."incusbr0";
        "userbr0" = interfaces."incusbr0";
        "userbr1" = interfaces."incusbr0";
      };
      logRefusedConnections = true;
      logRefusedPackets = true;
      logReversePathDrops = true;
      rejectPackets = true;
      filterForward = true;
      checkReversePath = lib.mkForce false;
      extraInputRules = ''
        iifname { ${internalInterfaces} } oifname { ${internalInterfaces}, ${externalInterfaces} } udp sport 41641 accept
        iifname { ${internalInterfaces} } oifname { ${internalInterfaces}, ${externalInterfaces} } udp dport 41641 accept
      '';
      extraForwardRules = ''
        ip version 4 iifname "tailscale0" accept
        ip version 4 oifname "tailscale0" accept
        ip version 4 iifname "incusbr0" accept
        ip version 4 oifname "incusbr0" accept
        ip version 4 iifname "incusbr1" accept
        ip version 4 oifname "incusbr1" accept
        ip version 4 iifname "userbr0" accept
        ip version 4 oifname "userbr0" accept
        ip version 4 iifname "userbr1" accept
        ip version 4 oifname "userbr1" accept
      '';
    };
  networking.nat = {
    enable = true;
    externalInterface = "enp3s0";
    internalInterfaces = [
      "enp3s0.3"
      "tailsacle0"
      # incus
      "incusbr0"
      "incusbr1"
      "userbr0"
      "userbr1"
    ];
  };

  # virtualisation (incus)
  virtualisation.incus = {
    enable = true;
    package = pkgs-unstable.incus;
  };
  security.apparmor.enable = false;

  # coredns
  services.coredns = {
    enable = true;
    config = ''
      default.incus.local {
        bind lo tailscale0

        secondary {
          transfer from 127.0.0.1:8445
        }
      }
    '';
  };

  # packages
  environment.systemPackages = (
    with pkgs;
    [
      # system
      parted
      multipath-tools
      testdisk
      pmutils

      # lang
      python3

      # editor
      micro
      hexedit

      # dev
      git

      # tools
      unzip
      ripgrep
      fzf
      screen
      tmux
      file

      # network
      bridge-utils
      dig
      tailscale
      iperf
      nettools
      tcpdump
      wget

      # monitoring
      iftop
      iotop
      sysstat

      # cert
      openssl
    ]
  );

  # programs
  programs.fish.enable = true;

  # services
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # datadog-agent
  services.datadog-agent = {
    enable = true;
    # https://ap1.datadoghq.com/organization-settings/api-keys?id=07deaf4e-6196-4b52-91f6-a1514f89d148
    site = "ap1.datadoghq.com";
    apiKeyFile = "/etc/datadog-keys/datadog_api_key";
    enableLiveProcessCollection = true;
    extraIntegrations = {
      openmetrics = pythonPackages: [ ];
    };
  };
}
