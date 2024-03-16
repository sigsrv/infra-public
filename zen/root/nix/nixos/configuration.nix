# /etc/nixos/configuration.nix
# nixos-help command or https://search.nixos.org/options

{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # host
  networking.hostName = "sigsrv";
  networking.hostId = "0d652ba8";  # zfs

  # nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # boot
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/6bc7857f-0502-47e5-90f8-f1d6c593ad10";
      preLVM = true;
      allowDiscards = true;
    };
  };

  # file systems
  fileSystems."/mnt/ubuntu" = {
    device = "/dev/disk/by-uuid/160dcea0-183a-4872-8e87-49e8299854fa";
    fsType = "ext4";
  };

  # users
  users.users.ecmaxp = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "lxd"
    ];
  };

  # locale
  i18n.defaultLocale = "en_US.UTF-8";

  # environment
  environment.variables = {
    EDITOR = "micro";
  };

  # packages
  environment.systemPackages = with pkgs; [
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

    # network
    tailscale
    iperf
    minicom
    nettools

    # monitoring
    iftop
    iotop
    sysstat
  ];

  # programs
  programs.fish.enable = true;

  # services
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = false;
  };
  services.datadog-agent = {
    enable = true;
    site = "ap1.datadoghq.com";
    apiKeyFile = "/run/datadog-keys/datadog_api_key";
    enableLiveProcessCollection = true;
  };

  # networking
  networking.vlans = {
    "enp4s0.100" = {
      id = 100;
      interface = "enp4s0";
    };
  };
  networking.firewall = {
    enable = true;
    interfaces = {
      "enp4s0.100" = {
        allowedTCPPorts = [ 22 ];
      };
    };
    trustedInterfaces = config.networking.nat.internalInterfaces;
  };
  networking.nat = {
    enable = true;
    internalInterfaces = [
      "lxdbr0"
      "sigsrv-nas"
      "sigsrv-try"
      "sigsrv-sdlc"
      "sigsrv-prod"
    ];
    externalInterface = "eno1";
  };

  # virtualisation
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true;
    zfsSupport = true;
    ui.enable = true;
  };
  virtualisation.lxc = {
    lxcfs.enable = true;
  };
  systemd.services.lxd = {
    restartIfChanged = false;
    path = [
      pkgs.util-linux
      config.boot.zfs.package
      "${config.boot.zfs.package}/lib/udev"
    ];
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # programs.mtr.enable = true;
  # system.copySystemConfiguration = true;

  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "23.11"; # Did you read the comment?
}
