terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "dns"
    }
  }
}

module "dns" {
  source = "../../../../../packages/aws/dns"
}

output "dns" {
  value = module.dns.route53_zone
}
