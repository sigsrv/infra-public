module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

resource "null_resource" "this" {
  triggers = {
    env  = local.env
    name = local.name
  }
}
