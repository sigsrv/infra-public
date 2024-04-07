terraform {
  cloud {
    organization = "sigsrv-prod-net"

    workspaces {
      name = "apps-srv-box"
    }
  }
}

module "dns" {
  source        = "../../../../shared/packages/aws/dns"
  public_domain = "srv.box"
}

output "dns" {
  value = module.dns.route53_zone
}
