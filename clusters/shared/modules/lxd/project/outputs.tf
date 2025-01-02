output "lxd_project_name" {
  value = lxd_project.this.name
}

output "lxd_storage_pool_name" {
  value = var.lxd_storage_pool_name
}

output "lxd_profile_name" {
  value = lxd_profile.this.name
}

output "lxd_dns_servers" {
  value = [
    split("/", lxd_network.this.config["ipv4.address"])[0],
    split("/", lxd_network.this.config["ipv6.address"])[0],
  ]
}

output "lxd_dns_domain" {
  value = lxd_network.this.config["dns.domain"]
}
