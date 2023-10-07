terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "vpc"
    }
  }
}


module "vpc" {
  source = "../../../../../packages/aws/vpc"

  vpc_cidr = local.config["vpc_cidr"]
  vpc_azs  = local.config["vpc_azs"]
}

locals {
  config = yamldecode(file("config.yaml"))
}

output "vpc" {
  value = module.vpc.vpc
}
