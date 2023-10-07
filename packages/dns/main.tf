module "metadata" {
  source = "../../modules/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

resource "aws_route53_zone" "this" {
  name = module.metadata.account_config["public_domain"]
  lifecycle {
    create_before_destroy = true
  }
}

output "route53_name_servers" {
  value = join("\n", aws_route53_zone.this.name_servers)
}
