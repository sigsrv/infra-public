terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-sigsrv-net"
    }
  }
}

module "aws_cloudfront_redirector" {
  source = "../../../../shared/services/aws_cloudfront_redirector"

  domain_names = [
    "sigsrv.net",
  ]

  target_url = "https://keybase.io/sigsrv"
}

output "domain_name" {
  value = module.aws_cloudfront_redirector.domain_name
}
