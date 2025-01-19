module "aws_cloudfront_redirectors" {
  for_each = var.aws_cloudfront_redirectors
  source   = "../../../../shared/apps/aws_cloudfront_redirector"

  name         = replace(local.name, local.package_name, each.key)
  domain_names = each.value.domain_names
  target_url   = each.value.target_url

  providers = {
    aws        = aws
    aws.global = aws.global
  }
}
