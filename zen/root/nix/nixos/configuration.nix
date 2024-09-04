# /etc/nixos/configuration.nix
# nixos-help command or https://search.nixos.org/options

{ config, lib, pkgs, inputs, ... }: {
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "23.11"; # Did you read the comment?

  imports = [
    ./hardware-configuration.nix
  ];

  # host
  networking.hostName = "sigsrv";
  networking.hostId = "0d652ba8";  # zfs

  # nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # zfs
  services.zfs.autoScrub.enable = true;

  # boot
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.kernelParams = [
    "zfs.zfs_arc_max=34359738368"  # 32 GB
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

  # networking
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  networking.timeServers = [
    "0.pool.ntp.org"
    "1.pool.ntp.org"
    "2.pool.ntp.org"
    "3.pool.ntp.org"
  ];
  networking.vlans = {
    "enp5s0.100" = {
      id = 100;
      interface = "enp5s0";
    };
  };
  networking.macvlans = {};
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 41641 ];
    interfaces = {
      "eno1" = {
        allowedTCPPorts = [];
        allowedUDPPorts = [];
      };
      "enp5s0.100" = {
        allowedTCPPorts = config.services.openssh.ports;
      };
      "lxdbr0" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
      "userbr0" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
      "sigsrv-nas" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
      "sigsrv-try" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
      "sigsrv-sdlc" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
      "sigsrv-prod" = { allowedUDPPorts = [ 53 67 1900 5351 ]; };
    };
    trustedInterfaces = ["enp5s0" "enp5s0.100"];
    logRefusedConnections = true;
    logRefusedPackets = true;
    logReversePathDrops = true;
    rejectPackets = true;
    # checkReversePath = "loose";
  };
  networking.nat = {
    # for LXD bridge: networking.nat.enable requires for operation bridge
    enable = true;

    internalIPs = [
      "192.168.0.0/24"
      "192.168.100.0/24"
    ];

    internalInterfaces = [
      "enp5s0.100"
      "lxdbr0"
      "userbr0"
      "sigsrv-nas"
      "sigsrv-try"
      "sigsrv-sdlc"
      "sigsrv-prod"
    ];

    externalInterface = "eno1";
  };

  # virtualisation
  security.apparmor.enable = true;
  virtualisation.lxd = {
    enable = true;
    ui.enable = true;
    recommendedSysctlSettings = true;
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
    bridge-utils
    dig
    tailscale
    iperf
    minicom
    nettools
    tcpdump

    # monitoring
    iftop
    iotop
    sysstat

    # cert
    openssl
  ];

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
    package = inputs.nixpkgs-legacy.legacyPackages.${pkgs.system}.datadog-agent;
    # https://ap1.datadoghq.com/organization-settings/api-keys?id=07deaf4e-6196-4b52-91f6-a1514f89d148
    site = "ap1.datadoghq.com";
    apiKeyFile = "/etc/datadog-keys/datadog_api_key";
    enableLiveProcessCollection = true;
    extraIntegrations = {
      openmetrics = pythonPackages: [];
    };
    checks = {
      openmetrics = {
        init_config = null;
        instances = [
          {
            openmetrics_endpoint = "https://127.0.0.1:8443/1.0/metrics";
            tls_verify = false;
            # sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 -keyout /etc/datadog-keys/lxd-metrics.key -nodes -out /etc/datadog-keys/lxd-metrics.crt -days 3650 -subj "/CN=metrics.local"
            # sudo lxc config trust add /etc/datadog-keys/lxd-metrics.crt --type=metrics
            tls_cert = "/etc/datadog-keys/lxd-metrics.crt";
            tls_private_key = "/etc/datadog-keys/lxd-metrics.key";
            tags = [ "service:lxd" ];
            max_returned_metrics = 50000;
            min_collection_interval = 10;
            metrics = [
              {
                lxd_cpu_seconds = {
                  name = "lxd.cpu.seconds";
                  type = "counter";
                  unit = "second";
                };
              }
              {
                lxd_cpu_effective_total = {
                  name = "lxd.cpu.effective.total";
                  type = "gauge";
                  unit = "cpu";
                };
              }
              {
                lxd_disk_read_bytes = {
                  name = "lxd.disk.read.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                lxd_disk_reads_completed = {
                  name = "lxd.disk.reads.completed";
                  type = "counter";
                };
              }
              {
                lxd_disk_written_bytes = {
                  name = "lxd.disk.written.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                lxd_disk_writes_completed = {
                  name = "lxd.disk.writes.completed";
                  type = "counter";
                };
              }
              {
                lxd_filesystem_avail_bytes = {
                  name = "lxd.filesystem.avail.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_filesystem_free_bytes = {
                  name = "lxd.filesystem.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_filesystem_size_bytes = {
                  name = "lxd.filesystem.size.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_alloc_bytes = {
                  name = "lxd.go.alloc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_alloc_bytes = {
                  name = "lxd.go.alloc.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                lxd_go_buck_hash_sys_bytes = {
                  name = "lxd.go.buck.hash.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_frees = {
                  name = "lxd.go.frees";
                  type = "counter";
                };
              }
              {
                lxd_go_gc_sys_bytes = {
                  name = "lxd.go.gc.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_goroutines = {
                  name = "lxd.go.goroutines";
                  type = "gauge";
                  unit = "thread";
                };
              }
              {
                lxd_go_heap_alloc_bytes = {
                  name = "lxd.go.heap.alloc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_heap_idle_bytes = {
                  name = "lxd.go.heap.idle.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_heap_inuse_bytes = {
                  name = "lxd.go.heap.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_heap_objects = {
                  name = "lxd.go.heap.objects";
                  type = "gauge";
                  unit = "object";
                };
              }
              {
                lxd_go_heap_released_bytes = {
                  name = "lxd.go.heap.released.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_heap_sys_bytes = {
                  name = "lxd.go.heap.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_lookups = {
                  name = "lxd.go.lookups";
                  type = "counter";
                };
              }
              {
                lxd_go_mallocs = {
                  name = "lxd.go.mallocs";
                  type = "counter";
                };
              }
              {
                lxd_go_mcache_inuse_bytes = {
                  name = "lxd.go.mcache.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_mcache_sys_bytes = {
                  name = "lxd.go.mcache.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_mspan_inuse_bytes = {
                  name = "lxd.go.mspan.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_mspan_sys_bytes = {
                  name = "lxd.go.mspan.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_next_gc_bytes = {
                  name = "lxd.go.next.gc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_other_sys_bytes = {
                  name = "lxd.go.other.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_stack_inuse_bytes = {
                  name = "lxd.go.stack.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_stack_sys_bytes = {
                  name = "lxd.go.stack.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_go_sys_bytes = {
                  name = "lxd.go.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Active_anon_bytes = {
                  name = "lxd.memory.active.anon.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Active_file_bytes = {
                  name = "lxd.memory.active.file.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Active_bytes = {
                  name = "lxd.memory.active.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Cached_bytes = {
                  name = "lxd.memory.cached.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Dirty_bytes = {
                  name = "lxd.memory.dirty.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_HugepagesFree_bytes = {
                  name = "lxd.memory.hugepages.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_HugepagesTotal_bytes = {
                  name = "lxd.memory.hugepages.total.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Inactive_anon_bytes = {
                  name = "lxd.memory.inactive.anon.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Inactive_file_bytes = {
                  name = "lxd.memory.inactive.file.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Inactive_bytes = {
                  name = "lxd.memory.inactive.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Mapped_bytes = {
                  name = "lxd.memory.mapped.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_MemAvailable_bytes = {
                  name = "lxd.memory.mem.available.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_MemFree_bytes = {
                  name = "lxd.memory.mem.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_MemTotal_bytes = {
                  name = "lxd.memory.mem.total.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_RSS_bytes = {
                  name = "lxd.memory.rss.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Shmem_bytes = {
                  name = "lxd.memory.shmem.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Swap_bytes = {
                  name = "lxd.memory.swap.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Unevictable_bytes = {
                  name = "lxd.memory.unevictable.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_Writeback_bytes = {
                  name = "lxd.memory.writeback.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                lxd_memory_OOM_kills = {
                  name = "lxd.memory.oom.kills";
                  type = "counter";
                };
              }
              {
                lxd_network_receive_bytes = {
                  name = "lxd.network.receive.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                lxd_network_receive_drop = {
                  name = "lxd.network.receive.drop";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_network_receive_errs = {
                  name = "lxd.network.receive.errs";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_network_receive_packets = {
                  name = "lxd.network.receive.packets";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_network_transmit_bytes = {
                  name = "lxd.network.transmit.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                lxd_network_transmit_drop = {
                  name = "lxd.network.transmit.drop";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_network_transmit_errs = {
                  name = "lxd.network.transmit.errs";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_network_transmit_packets = {
                  name = "lxd.network.transmit.packets";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                lxd_operations = {
                  name = "lxd.operations";
                  type = "counter";
                };
              }
              {
                lxd_procs_total = {
                  name = "lxd.procs.total";
                  type = "gauge";
                  unit = "process";
                };
              }
              {
                lxd_uptime_seconds = {
                  name = "lxd.uptime.seconds";
                  type = "gauge";
                  unit = "second";
                };
              }
              {
                lxd_warnings = {
                  name = "lxd.warnings";
                  type = "counter";
                };
              }
              {
                lxd_containers = {
                  name = "lxd.containers";
                  type = "gauge";
                  unit = "container";
                };
              }
              {
                lxd_vms = {
                  name = "lxd.vms";
                  type = "gauge";
                  unit = "instance";
                };
              }
            ];
          }
        ];
      };
    };
  };
}
