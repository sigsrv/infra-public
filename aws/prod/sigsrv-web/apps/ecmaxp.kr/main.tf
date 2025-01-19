terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-ecmaxp-kr"
    }
  }
}

module "aws_cloudfront_redirector" {
  source = "../../../../shared/services/aws_cloudfront_redirector"

  domain_names = [
    "ecmaxp.kr",
    "ecmaxp.pe.kr",
  ]

  target_url = "https://keybase.io/ecmaxp"
}

output "domain_name" {
  value = module.aws_cloudfront_redirector.domain_name
}
