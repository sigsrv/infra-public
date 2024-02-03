terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-ecmaxp-kr"
    }
  }
}

module "cloudfront_redirector" {
  source = "../../../../shared/packages/aws/cloudfront_redirector"

  domain_names = [
    "ecmaxp.kr",
    "ecmaxp.pe.kr",
    "ecmaxp.box",
  ]

  target_url = "https://keybase.io/ecmaxp"
}

output "domain_name" {
  value = module.cloudfront_redirector.domain_name
}
