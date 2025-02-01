terraform {
  backend "local" {}

  encryption {
    # "op://sigsrv-prod/sigsrv-infra tfstate encryption/password"
    key_provider "pbkdf2" "tfstate_encryption_passphrase" {
      passphrase = var.tfstate_encryption_passphrase
    }

    method "aes_gcm" "tfstate_encryption_passphrase" {
      keys = key_provider.pbkdf2.tfstate_encryption_passphrase
    }

    state {
      enforced = true
      method   = method.aes_gcm.tfstate_encryption_passphrase
    }

    plan {
      enforced = true
      method   = method.aes_gcm.tfstate_encryption_passphrase
    }
  }
}

variable "tfstate_encryption_passphrase" {
  type      = string
  nullable  = false
  sensitive = true
}
