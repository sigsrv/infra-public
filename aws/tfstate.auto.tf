# tfstate
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

locals {
  tfstate = {
    # aws
    region  = "ap-northeast-2"
    profile = local.tfstate_config.aws_profile
    assume_role = {
      role_arn = "arn:aws:iam::820242943905:role/sigsrv-infra-tfstate-${local.tfstate_config.aws_account_name}"
    }

    # dynamodb
    dynamodb_table = "sigsrv-infra-tfstate-lock"

    # s3
    bucket = "sigsrv-infra-tfstate"
    key = "${trimprefix(
      abspath(path.root),
      "/Users/ecmaxp/Library/Mobile Documents/com~apple~CloudDocs/Projects/sigsrv-infra/"
    )}/terraform.tfstate"
    encrypt = true

    # kms
    kms_key_id = "alias/sigsrv-infra-tfstate-kms-key"
    key_spec   = "AES_256"
  }
}
