terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

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
