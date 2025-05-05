# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the sigsrv-infra repository. It documents the infrastructure architecture, common operations, troubleshooting workflows, and best practices.

## Introduction and Sequential Thinking Approach

### Purpose and Usage

This document is organized using a sequential thinking approach that builds knowledge progressively. When working with this codebase, Claude should

- Break down complex problems into smaller, manageable steps
- Approach infrastructure tasks methodically from understanding to implementation
- Follow systematic diagnostic patterns for troubleshooting
- Consider dependencies and component relationships before making changes
- Use progressive refinement when designing and implementing solutions

### Important Notes for Cluster Operations

- Documentation First Approach

  - Always update CLAUDE.md with new instructions, workflows, or best practices BEFORE executing commands
  - Document any changes to workflows, configurations, or troubleshooting steps
  - This ensures documentation remains current and consistent with actual operations

- Just Command Usage

  - Always use the `just` command runner for executing common operations
  - Run `just --list` to see all available commands
  - Commands are prefixed by their category (e.g., `tofu-`, `incus-`, `kubectl-`)
  - All commands use appropriate flags and project configurations by default
  - Justfile is located in cluster directories and contains command descriptions and workflows
  - Review the justfile headers for common operation workflows and best practices

- Kubernetes Cluster Provisioning

  - When creating or updating Kubernetes clusters with OpenTofu, you must run `just tofu-apply` :multiple times: (at least 3-4 times)
  - Refer to the justfile for detailed explanation of this process

- Security Considerations:
  - Never read or display the contents of `kubeconfig` or `talosconfig` files
  - These files contain sensitive credentials and should be protected

- Rook-Ceph Maintenance:
  - Never delete the CephCluster resource or other Ceph CRDs directly
  - Do not use `kubectl delete cephcluster` as it can lead to resource leaks and data loss
  - Use the proper Rook-Ceph cleanup procedures as documented in Rook documentation
  - When troubleshooting OSDs, prefer to reset the underlying devices without destroying CRDs

### Sequential Problem-Solving Framework

When faced with a problem in this infrastructure

- Understand the context: What components and systems are involved?
- Define the problem: What specifically isn't working as expected?
- Gather information: Collect relevant logs, configurations, and statuses
- Analyze systematically: Follow the data flow through the system components
- Develop hypothesis: What are possible causes based on the evidence?
- Test incrementally: Make small, reversible changes to verify hypothesis
- Implement solution: Apply changes systematically
- Verify results: Confirm the problem is resolved and no new issues created

## Core Concepts and Mental Model

### Infrastructure Purpose and Design

The sigsrv-infra repository manages a multi-host virtualization infrastructure designed for running containerized workloads and virtual machines. It provides isolated network environments for various projects while enabling cross-host communication.

### Key Infrastructure Components

#### Physical Components

- Physical Hosts:
  - sigsrv: Primary host for system services
  - minisrv: Secondary host for additional capacity

#### Virtualization Layer

- Incus: A fork of LXD that manages Linux containers and VMs
  - Organized into projects for isolation
  - Provides virtualized compute, network, and storage resources

#### Networking Layer

- Network Bridges:
  - sigsrvbr0 (172.20.0.0/16): Primary system services network
  - incusbr0 (172.16.0.0/16): Management network
  - userbr0 (172.24.0.0/16): User workload network

#### Storage Layer

- Storage Pools:
  - nvme: Fast SSD storage for OS and applications
  - hdd: Large capacity storage for data
  - iso: Image storage for VM templates

#### Orchestration Layer

- Kubernetes Clusters:
  - Talos Linux based
  - Control plane and worker nodes
  - Various add-ons including Rook-Ceph for storage

#### Configuration Management

- OpenTofu: Infrastructure-as-code provisioning
- NixOS: Declarative host OS configuration

### Component Relationships

- Physical Hosts (sigsrv, minisrv)
  - Incus Layer
    - Compute Units
      - Kubernetes Orchestration
    - Network Bridges
      - Kubernetes Orchestration
    - Storage Pools
      - Kubernetes Orchestration

## Network Architecture

### Bridge Networks and VLANs

Each physical host has three main bridge networks that correspond to VLANs on the physical network

- sigsrvbr0:
  - VLAN ID: 20
  - VLAN Interface: sigsrv0
  - IP Range: 172.20.0.0/16
  - Purpose: System instances
- incusbr0:
  - VLAN ID: 16
  - VLAN Interface: incus0
  - IP Range: 172.16.0.0/16
  - Purpose: Incus management
- userbr0:
  - VLAN ID: 24
  - VLAN Interface: user0
  - IP Range: 172.24.0.0/16
  - Purpose: User instances

### Physical Network Topology

Both hosts (sigsrv, minisrv) share identical network structure

- Host Instances
  - User Instances → userbr0 → user0
  - System Instances → sigsrvbr0 → sigsrv0
  - Mgmt Instances → incusbr0 → incus0
- All VLAN interfaces (user0, sigsrv0, incus0) connect to Physical Network via VLAN Trunking

### Cross-Host Communication Requirements

For instances to communicate across physical hosts

- Bridge networks must have the same name on both hosts
- Each bridge must have its corresponding VLAN interface attached
- VLAN interfaces must have their IP configurations flushed before adding to bridges
- Physical switches must allow VLAN trunking between hosts

## Troubleshooting Guide

### Sequential Troubleshooting Approach

Follow this step-by-step process for all troubleshooting

- Identify the affected component or service
- Gather initial information: (logs, status, configuration)
- Check connectivity and dependencies: (network, storage, etc.)
- Analyze error messages and patterns
- Test with minimal configuration: to isolate the issue
- Apply targeted fixes: based on findings
- Verify the solution: works completely

### Network Connectivity Issues

#### Symptoms

- Instances cannot communicate across hosts
- `ping` fails between instances on different physical hosts
- Network services are unreachable

#### Diagnostic Workflow

- Verify Instance Network Configuration
- Test Local Connectivity
- Check Bridge Configuration
- Verify VLAN Interface Status
- Inspect IP Configurations on VLANs

See the justfile for specific commands to run for each step.

### Incus Cluster Issues

#### Symptoms

- Cluster members show as disconnected
- Operations fail with cluster-related errors
- Unable to target specific hosts

#### Diagnostic Steps

- Check Cluster Status
- Verify Cluster Member Configuration
- Check Incus Service Status

### Storage Issues

#### Symptoms

- Unable to create volumes
- Storage operations fail
- Instance cannot access storage

#### Diagnostic Steps

- Check Storage Pool Status
- Verify Storage Backend
- Check Storage Space

### Kubernetes Rook-Ceph Storage Issues

#### Symptoms

- PersistentVolumeClaims (PVCs) stuck in "Pending" state
- CephCluster shows "HEALTH_ERR" status
- Ceph Monitor pods in CrashLoopBackOff
- No Object Storage Devices (OSDs) detected
- Error message: "OSD count 0 < osd_pool_default_size"

#### Diagnostic Steps

- Check PVC Status
- Verify Ceph Health
- Check Ceph Component Pods
- Verify OSD Creation

See the justfile's "Rook-Ceph Storage Troubleshooting" workflow for detailed steps.

## Security Best Practices

### Network Security

- Use project-specific networks for isolation
- Apply network ACLs to restrict traffic between projects (later)
- Use proxy devices for controlled external access
- Limit bridge interfaces to only necessary VLANs

### Instance Security

- Keep base images updated
- Use minimal images with only required packages
- Configure instance restrictions appropriately
- Apply security.privileged=false unless absolutely necessary

### Project Isolation

- Create separate projects for different users/purposes
- Use project restrictions to limit resource usage
- Avoid sharing storage between projects

### Access Control

- Use role-based access control for admin access
- Implement least privilege access policies
- Regularly audit access logs

## Development Guidelines

### OpenTofu Style Guidelines

#### Naming Conventions

- Use `snake_case` for resource names and variables
- Prefix resources with their type (e.g., `instance_web`, `network_internal`)
- Use descriptive names that indicate purpose

#### Resource Organization

- Group related resources together
- Use modules for reusable components
- Apply meaningful tags to all resources

#### Code Quality

- Document variables with descriptions and types
- Use dynamic blocks for conditional resources
- Prefer `for_each` over `count` when possible
- Apply lifecycle rules for critical resources
- Use consistent indentation (2 spaces)

#### Example: Well-Structured OpenTofu Block

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
