terraform {
  cloud {
    organization = "sigsrv-prod-net"

    workspaces {
      name = "apps-svc-box"
    }
  }
}

module "dns" {
  source        = "../../../../shared/packages/aws/dns"
  public_domain = "svc.box"
}

output "dns" {
  value = module.dns.route53_zone
}

data "tfe_outputs" "sdlc" {
  organization = "sigsrv-sdlc-dev"
  workspace    = "apps-sdlc-svc-box"
}

resource "aws_route53_record" "sdlc" {
  zone_id = module.dns.route53_zone.zone_id
  name    = "sdlc"
  type    = "NS"
  ttl     = 300

  records = nonsensitive(data.tfe_outputs.sdlc.values["dns"]["name_servers"])
}
