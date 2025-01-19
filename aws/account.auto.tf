# providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84"
    }
  }
}

provider "aws" {
  profile             = var.aws_profile
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = local.aws_default_tags
  }
}

provider "aws" {
  alias               = "global"
  profile             = var.aws_profile
  region              = "us-east-1"
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = local.aws_default_tags
  }
}

# locals
locals {
  package_name = basename(abspath(path.root))

  aws_account_root_iam_arn = "arn:aws:iam::${var.aws_account_id}:root"

  aws_default_tags = {
    "sigsrv:terraform"   = "true"
    "sigsrv:workspace"   = local.name
    "sigsrv:application" = local.name
    "sigsrv:namespace"   = var.namespace
    "sigsrv:account"     = var.aws_account_name
    "sigsrv:env"         = var.env
    "sigsrv:package"     = local.package_name
    "sigsrv:name"        = local.name
  }

  name = (
    strcontains(var.aws_account_name, var.env)
    ? "${var.aws_account_name}-${local.package_name}"
    : "${var.aws_account_name}-${var.env}-${local.package_name}"
  )

  path = (
    strcontains(var.aws_account_name, var.env)
    ? "${var.aws_account_name}/${local.package_name}"
    : "${var.aws_account_name}/${var.env}/${local.package_name}"
  )
}

# variables
variable "namespace" {
  type = string
}

variable "workload" {
  type = string
}

variable "env" {
  type = string
}

# variables: aws
variable "aws_account_id" {
  type = string
}

variable "aws_account_name" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}
