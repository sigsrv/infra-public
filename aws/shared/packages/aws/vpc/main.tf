module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.aws.account_name # override for vpc
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.vpc_azs

  public_subnets   = [for k, v in var.vpc_azs : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets  = [for k, v in var.vpc_azs : cidrsubnet(var.vpc_cidr, 4, k + 8)]
  database_subnets = [for k, v in var.vpc_azs : cidrsubnet(var.vpc_cidr, 4, k + 12)]

  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false

  # dns
  enable_dns_support   = true
  enable_dns_hostnames = true

  # ipv6
  enable_ipv6                                   = true
  public_subnet_assign_ipv6_address_on_creation = true

  public_subnet_ipv6_prefixes = [0, 1, 2]
  private_subnet_ipv6_prefixes = [
    3, 4, 5
  ]
  database_subnet_ipv6_prefixes = [
    6, 7, 8
  ]
}
