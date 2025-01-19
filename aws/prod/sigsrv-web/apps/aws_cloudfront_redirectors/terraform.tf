terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-aws_cloudfront_redirectors"
    }
  }
}
