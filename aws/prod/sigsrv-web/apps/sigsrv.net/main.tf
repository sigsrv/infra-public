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
  ]

  target_url = "https://keybase.io/sigsrv"
}

output "domain_name" {
  value = module.cloudfront_redirector.domain_name
}
