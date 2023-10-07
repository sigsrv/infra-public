terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "ec2_key_pair"
    }
  }
}

module "ec2_key_pair" {
  source = "../../../../packages/ec2_key_pair"
}

output "ec2_key_pair" {
  value = module.ec2_key_pair.ec2_key_pair
}
