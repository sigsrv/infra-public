terraform {
  cloud {
    organization = "sigsrv-prod-nas"

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
