module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.0.1"

  description = local.name

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = true

  # Policy
  enable_default_policy = true

  # Aliases
  aliases = [local.name]

  # Config
  deletion_window_in_days = local.config["deletion_window_in_days"]
  enable_key_rotation     = local.config["enable_key_rotation"]

  tags = {

  }
}

locals {
  config = yamldecode(file("${path.module}/config/${local.env}.yaml"))
}
