terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-sigsrv-net"
    }
  }
}

module "cloudfront_redirector" {
  source = "../../../../shared/packages/aws/cloudfront_redirector"

  domain_names = [
    "sigsrv.net",
    "sigsrv.box",
  ]

  route53_records = {
    "sigsrv.box" = {
      zone_id = module.dns-sigsrv-box.route53_zone.zone_id
    }
  }

  target_url = "https://keybase.io/sigsrv"
}

output "domain_name" {
  value = module.cloudfront_redirector.domain_name
}

module "dns-sigsrv-box" {
  source        = "../../../../shared/packages/aws/dns"
  public_domain = "sigsrv.box"
}

output "dns-sigsrv-box" {
  value = module.dns-sigsrv-box.route53_zone
}
