module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

locals {
  public_domain = coalesce(var.public_domain, lookup(module.metadata.aws_account_config, "public_domain", null))
}

resource "aws_route53_zone" "this" {
  name = local.public_domain
  lifecycle {
    create_before_destroy = true
  }
}

output "route53_name_servers" {
  value = join("\n", aws_route53_zone.this.name_servers)
}
