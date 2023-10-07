terraform {
  cloud {
    organization = "sigsrv-prod-nas"

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
