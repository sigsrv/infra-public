module "metadata" {
  source = "../../modules/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

resource "aws_ec2_managed_prefix_list" "this" {
  address_family = "IPv4"
  max_entries    = 1
  name           = local.name
}

module "my_public_ip" {
  source = "../../modules/my_public_ip"
}

locals {
  my_public_ip = module.my_public_ip.my_public_ip
}

resource "aws_ec2_managed_prefix_list_entry" "this" {
  prefix_list_id = aws_ec2_managed_prefix_list.this.id
  cidr           = "${local.my_public_ip}/32"
}
