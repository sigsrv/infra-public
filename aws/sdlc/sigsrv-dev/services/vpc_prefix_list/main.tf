terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "vpc_prefix_list"
    }
  }
}

module "vpc_prefix_list" {
  source = "../../../../shared/packages/aws/vpc_prefix_list"
}

output "vpc_prefix_list" {
  value = module.vpc_prefix_list.vpc_prefix_list
}
