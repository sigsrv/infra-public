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
  system.stateVersion = "23.11"; # Did you read the comment?

  imports = [
    ./hardware-configuration.nix
    ./datadog.nix
  ];

  # host
  networking.hostName = "sigsrv";
  networking.hostId = "0d652ba8"; # zfs

  # zfs
  services.zfs.autoScrub.enable = true;

  # boot
  boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.kernelParams = [
    "zfs.zfs_arc_max=17179869184" # 16 GB
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/6bc7857f-0502-47e5-90f8-f1d6c593ad10";
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
  networking.interfaces = {
    "enp5s0m1" = { };
  };
  networking.macvlans = {
    "enp5s0m1" = {
      interface = "enp5s0";
      mode = "vepa";
    };
  };
  networking.vlans = {
    "enp5s0.3" = {
      id = 3;
      interface = "enp5s0";
    };
  };
  networking.dhcpcd = {
    denyInterfaces = [
      "veth*"
      "mac*"
    ];
    extraConfig = ''
      interface enp5s0
      metric 1000

      interface enp5s0d1
      metric 1001
    '';
  };
  networking.nftables.enable = true;
  networking.firewall =
    let
      internalInterfaces = "${lib.concatStringsSep ", " (
        map (x: ''"${x}"'') [
          "enp5s0.3"
          "incusbr0"
          "incusbr1"
          "userbr0"
          "userbr1"
        ]
      )}";
      externalInterfaces = "${lib.concatStringsSep ", " (
        map (x: ''"${x}"'') [
          "enp5s0"
          "enp5s0m1"
        ]
      )}";
    in
    rec {
      enable = true;
      allowedUDPPorts = [ 41641 ];
      trustedInterfaces = [ "tailscale0" ];
      interfaces = {
        "enp5s0.3" = {
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
    externalInterface = "enp5s0";
    internalInterfaces = [
      "enp5s0.3"
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
    ui.enable = true;
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
  environment.systemPackages =
    (with pkgs; [
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
    ])
    ++ (with pkgs-unstable; [
      incus
    ]);

  # programs
  programs.fish.enable = true;

  # services
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };
  services.openssh = {
    enable = true;
    openFirewall = false;
  };
}
