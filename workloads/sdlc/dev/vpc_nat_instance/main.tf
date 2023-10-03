terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "vpc_nat_instance"
    }
  }
}

module "vpc_nat_instance" {
  source = "../../../../projects/vpc_nat_instance"

  ec2_key_pair    = local.ec2_key_pair
  vpc             = local.vpc
  vpc_prefix_list = local.vpc_prefix_list
}

locals {
  ec2_key_pair    = data.tfe_outputs.ec2_key_pair.nonsensitive_values.ec2_key_pair
  vpc             = data.tfe_outputs.vpc.nonsensitive_values.vpc
  vpc_prefix_list = data.tfe_outputs.vpc_prefix_list.nonsensitive_values.vpc_prefix_list
}

data "tfe_outputs" "ec2_key_pair" {
  organization = "sigsrv-sdlc-dev"
  workspace    = "ec2_key_pair"
}

data "tfe_outputs" "vpc" {
  organization = "sigsrv-sdlc-dev"
  workspace    = "vpc"
}

data "tfe_outputs" "vpc_prefix_list" {
  organization = "sigsrv-sdlc-dev"
  workspace    = "vpc_prefix_list"
}

output "vpc_nat_instance" {
  value = module.vpc_nat_instance.vpc_nat_instance
}
