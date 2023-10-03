terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "kms"
    }
  }
}

module "kms" {
  source = "../../../../projects/kms"
}

output "kms" {
  value = module.kms.kms
}
