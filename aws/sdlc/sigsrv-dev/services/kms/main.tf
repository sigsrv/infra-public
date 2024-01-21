terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "kms"
    }
  }
}

module "kms" {
  source = "../../../../../packages/aws/kms"
}

output "kms" {
  value = module.kms.kms
}
