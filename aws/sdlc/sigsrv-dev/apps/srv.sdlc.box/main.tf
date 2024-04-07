terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "apps-srv-sdlc-box"
    }
  }
}

module "dns" {
  source        = "../../../../shared/packages/aws/dns"
  public_domain = "srv.sdlc.box"
}

output "dns" {
  value = module.dns.route53_zone
}

data "tfe_outputs" "dns-root" {
  organization = "sigsrv-sdlc-dev"
  workspace    = "dns"
}

resource "aws_route53_record" "dns-root-srv-ns" {
  zone_id = nonsensitive(data.tfe_outputs.dns-root.values["dns"]["zone_id"])
  name    = "srv"
  type    = "NS"
  ttl     = 300

  records = module.dns.route53_zone.name_servers
}
