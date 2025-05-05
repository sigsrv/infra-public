# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the sigsrv-infra repository. It documents the infrastructure architecture, common operations, troubleshooting workflows, and best practices.

## 1. Infrastructure Overview

### Purpose and Design

The sigsrv-infra repository manages a multi-host virtualization infrastructure designed for running containerized workloads and virtual machines. It provides isolated network environments for various projects while enabling cross-host communication.

### Key Components

- **Physical Hosts**: 
  - sigsrv: Primary host for system services
  - minisrv: Secondary host for additional capacity

- **Virtualization Platform**:
  - Incus: A fork of LXD that manages Linux containers and VMs
  - Organized into projects for isolation

- **Network Architecture**:
  ```
  ┌────────────┐                     ┌────────────┐
  │   sigsrv   │                     │   minisrv  │
  │            │                     │            │
  │ ┌────────┐ │                     │ ┌────────┐ │
  │ │Instance│ │                     │ │Instance│ │
  │ └────────┘ │                     │ └────────┘ │
  │     │      │                     │     │      │
  │  sigsrvbr0 │                     │  sigsrvbr0 │
  │     │      │                     │     │      │
  │  sigsrv0   │      Physical       │  sigsrv0   │
  │     │      │      Network        │     │      │
  └─────┼──────┘     Connection      └─────┼──────┘
        │      ───────────────────────     │
        │          VLAN ID 20 (172.20/16)  │
  ```

- **Storage Pools**:
  - nvme: Fast SSD storage for OS and applications
  - hdd: Large capacity storage for data
  - iso: Image storage for VM templates

- **Networks**:
  - sigsrvbr0 (172.20.0.0/16): Primary system services network
  - incusbr0 (172.16.0.0/16): Management network
  - userbr0 (172.24.0.0/16): User workload network

- **Configuration Management**:
  - Terraform/OpenTofu: Infrastructure-as-code provisioning
  - NixOS: Declarative host OS configuration

## 2. Tools and Command Reference

### Why Use These Tools

- **Terraform/OpenTofu**: For declarative, version-controlled infrastructure provisioning
- **Incus CLI**: For direct management and troubleshooting of containers and VMs
- **Linux Networking Tools**: For diagnosing and fixing network connectivity issues

### Terraform/OpenTofu Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform fmt -recursive` | Format code according to standards | Cleanup before commits |
| `terraform validate` | Verify configuration syntax | Check for errors before planning |
| `terraform plan` | Preview changes | See what would change before applying |
| `terraform apply` | Apply infrastructure changes | Deploy infrastructure updates |
| `terraform destroy -target=resource_type.resource_name` | Remove specific resources | Delete a specific instance or network |

```bash
# Workflow: Make a change to infrastructure
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

### Incus CLI for Container/VM Management

| Category | Command | Purpose |
|----------|---------|---------|
| **Projects** | `incus project list` | List all projects |
| | `incus project create <name>` | Create a new project |
| | `incus project switch <name>` | Change to a different project |
| | `incus project delete <name>` | Delete a project (must be empty) |
| **Instances** | `incus launch <image> <name> --network <net> --storage <pool>` | Create a new instance |
| | `incus list [--project <project>]` | List all instances |
| | `incus start/stop/restart <name>` | Control instance state |
| | `incus delete <name>` | Remove an instance |
| **Networking** | `incus network list` | Show available networks |
| | `incus network show <name> --target <host>` | Get network configuration |
| | `incus network create <name> <type>` | Create a new network |
| **Storage** | `incus storage list` | Show storage pools |
| | `incus storage volume list <pool>` | List volumes in a pool |

```bash
# Workflow: Create a new instance in a project
incus project switch myproject
incus launch images:ubuntu/22.04 webserver --network sigsrvbr0 --storage nvme
incus list
incus exec webserver -- apt update && apt upgrade -y
```

### Bridge and VLAN Management

| Command | Purpose |
|---------|---------|
| `brctl show` | Display bridge interfaces and their attached interfaces |
| `brctl addif <bridge> <interface>` | Add an interface to a bridge |
| `ip addr show [dev <interface>]` | Show IP addresses for interfaces |
| `ip addr flush dev <interface>` | Remove IP configuration from an interface |
| `ip link set <interface> up/down` | Enable/disable a network interface |

## 3. Common Workflows

### Creating a New User Environment

1. **Create Project**:
   ```bash
   incus project create user-john
   incus project switch user-john
   ```

2. **Configure Network Access**:
   ```bash
   # Set up network ACLs (if needed)
   incus network acl create john-acl
   incus network acl rule add john-acl egress accept tcp --protocol tcp
   incus network acl rule add john-acl ingress accept tcp --protocol tcp
   
   # Apply ACL to user network
   incus network set userbr0 security.acls=john-acl
   ```

3. **Create Storage**:
   ```bash
   # Create user storage volume
   incus storage volume create nvme john-data
   ```

4. **Launch User Instance**:
   ```bash
   incus launch images:ubuntu/22.04 john-vm1 --network userbr0 --storage nvme
   
   # Add storage to instance
   incus storage volume attach nvme john-data john-vm1 /data
   ```

5. **Configure Access**:
   ```bash
   # Set up SSH key
   incus exec john-vm1 -- mkdir -p /root/.ssh
   incus file push authorized_keys john-vm1/root/.ssh/authorized_keys
   ```

### Setting Up Cross-Host Network Communication

1. **Verify Current Network Configuration**:
   ```bash
   ssh sigsrv -- 'brctl show'
   ssh minisrv -- 'brctl show'
   ```

2. **Check VLAN Interfaces**:
   ```bash
   ssh sigsrv -- 'ip addr show sigsrv0'
   ssh minisrv -- 'ip addr show sigsrv0'
   ```

3. **Flush IP Addresses (if needed)**:
   ```bash
   ssh sigsrv -- 'sudo ip addr flush dev sigsrv0'
   ssh minisrv -- 'sudo ip addr flush dev sigsrv0'
   ```

4. **Add Interfaces to Bridges**:
   ```bash
   ssh sigsrv -- 'sudo brctl addif sigsrvbr0 sigsrv0'
   ssh minisrv -- 'sudo brctl addif sigsrvbr0 sigsrv0'
   ```

5. **Test Connectivity**:
   ```bash
   # Create test instances on different hosts
   incus launch images:ubuntu/22.04 s1 --network sigsrvbr0 --target sigsrv
   incus launch images:ubuntu/22.04 s2 --network sigsrvbr0 --target minisrv
   
   # Test connectivity
   incus list  # To get IPs
   incus exec s1 -- ping -c 4 <s2_ip>
   ```

## 4. Troubleshooting Guide

### Network Connectivity Issues

#### Symptoms
- Instances cannot communicate across hosts
- `ping` fails between instances on different physical hosts
- Network services are unreachable

#### Diagnostic Workflow
1. **Verify Instance Network Configuration**:
   ```bash
   # Check instance network status
   incus list  # Note the IPs and networks
   incus info <instance_name>  # Check network configuration
   ```

2. **Test Local Connectivity**:
   ```bash
   # Test connectivity to gateway
   incus exec <instance> -- ping -c 4 <network_gateway>
   ```

3. **Check Bridge Configuration**:
   ```bash
   # Check bridges on each host
   ssh sigsrv -- 'brctl show'
   ssh minisrv -- 'brctl show'
   ```

4. **Verify VLAN Interface Status**:
   ```bash
   # Check VLAN interfaces on each host
   ssh sigsrv -- 'ip addr show'
   ssh minisrv -- 'ip addr show'
   ```

5. **Inspect IP Configurations on VLANs**:
   ```bash
   ssh sigsrv -- 'ip addr show sigsrv0'
   ssh minisrv -- 'ip addr show sigsrv0'
   ```

#### Common Solutions
1. **Fix Missing VLAN Interface on Bridge**:
   ```bash
   ssh <host> -- 'sudo ip addr flush dev <vlan_interface>'
   ssh <host> -- 'sudo brctl addif <bridge_name> <vlan_interface>'
   ```

2. **Reset Network Interface**:
   ```bash
   ssh <host> -- 'sudo ip link set <interface> down'
   ssh <host> -- 'sudo ip link set <interface> up'
   ```

3. **Restart Network Service** (if needed):
   ```bash
   ssh <host> -- 'sudo systemctl restart networking'
   ```

### Incus Cluster Issues

#### Symptoms
- Cluster members show as disconnected
- Operations fail with cluster-related errors
- Unable to target specific hosts

#### Diagnostic Steps
1. **Check Cluster Status**:
   ```bash
   incus cluster list
   ```

2. **Verify Cluster Member Configuration**:
   ```bash
   incus cluster show <member>
   ```

3. **Check Incus Service Status**:
   ```bash
   ssh <host> -- 'systemctl status incus'
   ssh <host> -- 'journalctl -u incus -n 100'
   ```

#### Common Solutions
1. **Restart Incus Service**:
   ```bash
   ssh <host> -- 'sudo systemctl restart incus'
   ```

2. **Verify Firewall Rules**:
   ```bash
   ssh <host> -- 'sudo iptables -L'
   ```

### Storage Issues

#### Symptoms
- Unable to create volumes
- Storage operations fail
- Instance cannot access storage

#### Diagnostic Steps
1. **Check Storage Pool Status**:
   ```bash
   incus storage list
   incus storage info <pool> --target <host>
   ```

2. **Verify Storage Backend**:
   ```bash
   ssh <host> -- 'zpool status'  # For ZFS pools
   ```

3. **Check Storage Space**:
   ```bash
   ssh <host> -- 'df -h'
   ```

#### Common Solutions
1. **Clean Up Unused Volumes**:
   ```bash
   incus storage volume list <pool>
   incus storage volume delete <pool> <volume>
   ```

2. **Expand Storage Pool** (if needed):
   ```bash
   ssh <host> -- 'zpool add <pool> <device>'  # For ZFS
   ```

## 5. Network Architecture Details

### Bridge Networks and VLANs

Each physical host has three main bridge networks that correspond to VLANs on the physical network:

| Bridge    | VLAN ID | VLAN Interface | IP Range        | Purpose           |
|-----------|---------|----------------|-----------------|-------------------|
| sigsrvbr0 | 20      | sigsrv0        | 172.20.0.0/16   | System instances  |
| incusbr0  | 16      | incus0         | 172.16.0.0/16   | Incus management  |
| userbr0   | 24      | user0          | 172.24.0.0/16   | User instances    |

### Cross-Host Communication Requirements

For instances to communicate across physical hosts:

1. Bridge networks must have the same name on both hosts
2. Each bridge must have its corresponding VLAN interface attached
3. VLAN interfaces must have their IP configurations flushed before adding to bridges
4. Physical switches must allow VLAN trunking between hosts

### Network Topology

```
Physical Host: sigsrv                   Physical Host: minisrv
┌────────────────────────┐              ┌────────────────────────┐
│                        │              │                        │
│  ┌─────────────────┐   │              │  ┌─────────────────┐   │
│  │  User Instances │   │              │  │  User Instances │   │
│  └────────┬────────┘   │              │  └────────┬────────┘   │
│           │            │              │           │            │
│        userbr0         │              │        userbr0         │
│           │            │              │           │            │
│         user0          │              │         user0          │
│           │            │              │           │            │
├───────────┼────────────┤              ├───────────┼────────────┤
│           │            │              │           │            │
│  ┌────────┴────────┐   │              │  ┌────────┴────────┐   │
│  │ System Instances│   │              │  │ System Instances│   │
│  └────────┬────────┘   │              │  └────────┬────────┘   │
│           │            │              │           │            │
│       sigsrvbr0        │              │       sigsrvbr0        │
│           │            │              │           │            │
│        sigsrv0         │              │        sigsrv0         │
│           │            │              │           │            │
├───────────┼────────────┤              ├───────────┼────────────┤
│           │            │              │           │            │
│  ┌────────┴────────┐   │              │  ┌────────┴────────┐   │
│  │ Mgmt Instances  │   │              │  │ Mgmt Instances  │   │
│  └────────┬────────┘   │              │  └────────┬────────┘   │
│           │            │              │           │            │
│        incusbr0        │              │        incusbr0        │
│           │            │              │           │            │
│         incus0         │              │         incus0         │
│           │            │              │           │            │
└───────────┼────────────┘              └───────────┼────────────┘
            │                                       │
            └───────────────┬───────────────────────┘
                            │
                     Physical Network
                    (VLAN Trunking)
```

## 6. Security Best Practices

### Network Security

- Use project-specific networks for isolation
- Apply network ACLs to restrict traffic between projects
- Use proxy devices for controlled external access
- Limit bridge interfaces to only necessary VLANs

```bash
# Create network ACL
incus network acl create restrictive
incus network acl rule add restrictive egress deny all
incus network acl rule add restrictive ingress deny all
incus network acl rule add restrictive egress allow tcp dst=80,443
```

### Instance Security

- Keep base images updated
- Use minimal images with only required packages
- Configure instance restrictions appropriately
- Apply security.privileged=false unless absolutely necessary

```bash
# Set security limits on instances
incus config set instancename security.privileged false
incus config set instancename limits.cpu=2
incus config set instancename limits.memory=2GB
```

### Project Isolation

- Create separate projects for different users/purposes
- Use project restrictions to limit resource usage
- Avoid sharing storage between projects

```bash
# Create restricted project
incus project create restricted
incus project set restricted features.images=false
incus project set restricted restricted=true
```

### Access Control

- Use role-based access control for admin access
- Implement least privilege access policies
- Regularly audit access logs

## 7. Terraform/OpenTofu Style Guidelines

### Naming Conventions

- Use `snake_case` for resource names and variables
- Prefix resources with their type (e.g., `instance_web`, `network_internal`)
- Use descriptive names that indicate purpose

### Resource Organization

- Group related resources together
- Use modules for reusable components
- Apply meaningful tags to all resources

### Code Quality

- Document variables with descriptions and types
- Use dynamic blocks for conditional resources
- Prefer `for_each` over `count` when possible
- Apply lifecycle rules for critical resources
- Use consistent indentation (2 spaces)

### Example: Well-Structured Terraform Block

```hcl
resource "incus_instance" "web_server" {
  name        = "web-${var.environment}"
  image       = var.server_image
  project     = var.project_name
  profiles    = ["default"]
  
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = incus_network.internal.name
    }
  }
  
  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2GB"
  }
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}
```

## 8. Maintenance Procedures

### Backups

- **Backing Up Incus Configuration**:
  ```bash
  incus export <instance_name> ./backups/<instance_name>-$(date +%Y%m%d).tar.gz
  ```

- **Storage Volume Snapshots**:
  ```bash
  incus storage volume snapshot create <pool> <volume> <snapshot_name>
  incus storage volume snapshot copy <pool> <volume>/<snapshot> <new_pool> <new_volume>
  ```

### Updates

- **Updating Incus**:
  ```bash
  ssh <host> -- 'sudo apt update && sudo apt upgrade -y incus'
  ```

- **Checking Cluster Status After Updates**:
  ```bash
  incus cluster list
  incus info --target <host>
  ```

### Health Checks

- **System Resources**:
  ```bash
  ssh <host> -- 'free -h'
  ssh <host> -- 'df -h'
  ssh <host> -- 'top -b -n 1'
  ```

- **Network Health**:
  ```bash
  # Check bridge status
  ssh <host> -- 'brctl show'
  
  # Verify VLAN interfaces
  ssh <host> -- 'ip addr show | grep vlan'
  ```

- **Storage Health**:
  ```bash
  # Check ZFS pool status
  ssh <host> -- 'zpool status'
  ssh <host> -- 'zpool list'
  ```