output "type" {
  value = var.node.type
}

output "config" {
  value = incus_instance.this.config
}

output "phase" {
  value = phaser_sequential.this.phase
}

output "endpoint" {
  value = (
    length(incus_network_zone_record.this) > 0
    ? "${incus_network_zone_record.this[0].name}.${incus_network_zone_record.this[0].zone}"
    : null
  )
}

output "ipv4_address" {
  value = incus_instance.this.ipv4_address
}
