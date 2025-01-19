module "aws_cloudfront_redirector" {
  source = "../../../../shared/services/aws_cloudfront_redirector"

  name         = local.name
  domain_names = var.domain_names
  target_url   = var.target_url

  providers = {
    aws        = aws
    aws.global = aws.global
  }
}
