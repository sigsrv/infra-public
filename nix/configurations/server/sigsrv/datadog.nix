{ ... }:
{
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
    checks = {
      openmetrics = {
        init_config = null;
        instances = [
          {
            openmetrics_endpoint = "https://127.0.0.1:8443/1.0/metrics";
            tls_verify = false;
            # sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -sha384 -keyout /etc/datadog-keys/incus-metrics.key -nodes -out /etc/datadog-keys/incus-metrics.crt -days 3650 -subj "/CN=metrics.local"
            # sudo incus config trust add-certificate /etc/datadog-keys/incus-metrics.crt --type=metrics
            tls_cert = "/etc/datadog-keys/incus-metrics.crt";
            tls_private_key = "/etc/datadog-keys/incus-metrics.key";
            tags = [ "service:incus" ];
            max_returned_metrics = 50000;
            min_collection_interval = 10;
            metrics = [
              {
                incus_cpu_seconds = {
                  name = "incus.cpu.seconds";
                  type = "counter";
                  unit = "second";
                };
              }
              {
                incus_cpu_effective_total = {
                  name = "incus.cpu.effective.total";
                  type = "gauge";
                  unit = "cpu";
                };
              }
              {
                incus_disk_read_bytes = {
                  name = "incus.disk.read.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                incus_disk_reads_completed = {
                  name = "incus.disk.reads.completed";
                  type = "counter";
                };
              }
              {
                incus_disk_written_bytes = {
                  name = "incus.disk.written.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                incus_disk_writes_completed = {
                  name = "incus.disk.writes.completed";
                  type = "counter";
                };
              }
              {
                incus_filesystem_avail_bytes = {
                  name = "incus.filesystem.avail.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_filesystem_free_bytes = {
                  name = "incus.filesystem.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_filesystem_size_bytes = {
                  name = "incus.filesystem.size.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_alloc_bytes = {
                  name = "incus.go.alloc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_alloc_bytes = {
                  name = "incus.go.alloc.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                incus_go_buck_hash_sys_bytes = {
                  name = "incus.go.buck.hash.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_frees = {
                  name = "incus.go.frees";
                  type = "counter";
                };
              }
              {
                incus_go_gc_sys_bytes = {
                  name = "incus.go.gc.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_goroutines = {
                  name = "incus.go.goroutines";
                  type = "gauge";
                  unit = "thread";
                };
              }
              {
                incus_go_heap_alloc_bytes = {
                  name = "incus.go.heap.alloc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_heap_idle_bytes = {
                  name = "incus.go.heap.idle.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_heap_inuse_bytes = {
                  name = "incus.go.heap.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_heap_objects = {
                  name = "incus.go.heap.objects";
                  type = "gauge";
                  unit = "object";
                };
              }
              {
                incus_go_heap_released_bytes = {
                  name = "incus.go.heap.released.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_heap_sys_bytes = {
                  name = "incus.go.heap.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_lookups = {
                  name = "incus.go.lookups";
                  type = "counter";
                };
              }
              {
                incus_go_mallocs = {
                  name = "incus.go.mallocs";
                  type = "counter";
                };
              }
              {
                incus_go_mcache_inuse_bytes = {
                  name = "incus.go.mcache.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_mcache_sys_bytes = {
                  name = "incus.go.mcache.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_mspan_inuse_bytes = {
                  name = "incus.go.mspan.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_mspan_sys_bytes = {
                  name = "incus.go.mspan.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_next_gc_bytes = {
                  name = "incus.go.next.gc.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_other_sys_bytes = {
                  name = "incus.go.other.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_stack_inuse_bytes = {
                  name = "incus.go.stack.inuse.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_stack_sys_bytes = {
                  name = "incus.go.stack.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_go_sys_bytes = {
                  name = "incus.go.sys.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Active_anon_bytes = {
                  name = "incus.memory.active.anon.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Active_file_bytes = {
                  name = "incus.memory.active.file.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Active_bytes = {
                  name = "incus.memory.active.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Cached_bytes = {
                  name = "incus.memory.cached.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Dirty_bytes = {
                  name = "incus.memory.dirty.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_HugepagesFree_bytes = {
                  name = "incus.memory.hugepages.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_HugepagesTotal_bytes = {
                  name = "incus.memory.hugepages.total.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Inactive_anon_bytes = {
                  name = "incus.memory.inactive.anon.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Inactive_file_bytes = {
                  name = "incus.memory.inactive.file.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Inactive_bytes = {
                  name = "incus.memory.inactive.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Mapped_bytes = {
                  name = "incus.memory.mapped.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_MemAvailable_bytes = {
                  name = "incus.memory.mem.available.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_MemFree_bytes = {
                  name = "incus.memory.mem.free.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_MemTotal_bytes = {
                  name = "incus.memory.mem.total.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_RSS_bytes = {
                  name = "incus.memory.rss.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Shmem_bytes = {
                  name = "incus.memory.shmem.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Swap_bytes = {
                  name = "incus.memory.swap.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Unevictable_bytes = {
                  name = "incus.memory.unevictable.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_Writeback_bytes = {
                  name = "incus.memory.writeback.bytes";
                  type = "gauge";
                  unit = "byte";
                };
              }
              {
                incus_memory_OOM_kills = {
                  name = "incus.memory.oom.kills";
                  type = "counter";
                };
              }
              {
                incus_network_receive_bytes = {
                  name = "incus.network.receive.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                incus_network_receive_drop = {
                  name = "incus.network.receive.drop";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_network_receive_errs = {
                  name = "incus.network.receive.errs";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_network_receive_packets = {
                  name = "incus.network.receive.packets";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_network_transmit_bytes = {
                  name = "incus.network.transmit.bytes";
                  type = "counter";
                  unit = "byte";
                };
              }
              {
                incus_network_transmit_drop = {
                  name = "incus.network.transmit.drop";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_network_transmit_errs = {
                  name = "incus.network.transmit.errs";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_network_transmit_packets = {
                  name = "incus.network.transmit.packets";
                  type = "counter";
                  unit = "packet";
                };
              }
              {
                incus_operations = {
                  name = "incus.operations";
                  type = "counter";
                };
              }
              {
                incus_procs_total = {
                  name = "incus.procs.total";
                  type = "gauge";
                  unit = "process";
                };
              }
              {
                incus_uptime_seconds = {
                  name = "incus.uptime.seconds";
                  type = "gauge";
                  unit = "second";
                };
              }
              {
                incus_warnings = {
                  name = "incus.warnings";
                  type = "counter";
                };
              }
              {
                incus_containers = {
                  name = "incus.containers";
                  type = "gauge";
                  unit = "container";
                };
              }
              {
                incus_vms = {
                  name = "incus.vms";
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
