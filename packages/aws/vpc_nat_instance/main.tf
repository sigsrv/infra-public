module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  # Error: expected length of name_prefix to be in the range (1 - 38)
  # module.nat_instance.aws_iam_role.this
  name = substr(module.metadata.name, 0, 38)
}

module "nat_instance" {
  source  = "int128/nat-instance/aws"
  version = "2.1.0"

  name                        = local.name
  vpc_id                      = var.vpc.vpc_id
  public_subnet               = var.vpc.public_subnets[0]
  private_subnets_cidr_blocks = var.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = var.vpc.private_route_table_ids
  key_name                    = var.ec2_key_pair.key_name
}

resource "aws_eip" "nat_instance" {
  network_interface = module.nat_instance.eni_id

  tags = {
    "Name" = local.name
  }
}

resource "aws_security_group_rule" "ssh" {
  count = var.enable_ssh ? 1 : 0

  security_group_id = module.nat_instance.sg_id

  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  prefix_list_ids = [var.vpc_prefix_list.id]
}

resource "aws_security_group_rule" "egress_ipv6" {
  security_group_id = module.nat_instance.sg_id

  type             = "egress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  ipv6_cidr_blocks = ["::/0"]
}
