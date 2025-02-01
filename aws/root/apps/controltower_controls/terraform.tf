terraform {
  backend "s3" {
    profile        = local.tfstate.profile
    region         = local.tfstate.region
    assume_role    = local.tfstate.assume_role
    bucket         = local.tfstate.bucket
    key            = local.tfstate.key
    encrypt        = local.tfstate.encrypt
    dynamodb_table = local.tfstate.dynamodb_table
  }

  encryption {
    key_provider "aws_kms" "kms_key" {
      profile     = local.tfstate.profile
      region      = local.tfstate.region
      assume_role = local.tfstate.assume_role
      kms_key_id  = local.tfstate.kms_key_id
      key_spec    = local.tfstate.key_spec
    }

    method "aes_gcm" "kms_key" {
      keys = key_provider.aws_kms.kms_key
    }

    state {
      enforced = true
      method   = method.aes_gcm.kms_key
    }

    plan {
      enforced = true
      method   = method.aes_gcm.kms_key
    }
  }
}
