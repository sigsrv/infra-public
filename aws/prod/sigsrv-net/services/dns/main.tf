terraform {
  cloud {
    organization = "sigsrv-prod-net"

    workspaces {
      name = "dns"
    }
  }
}

module "dns" {
  source = "../../../../shared/packages/aws/dns"
}

output "dns" {
  value = module.dns.route53_zone
}
