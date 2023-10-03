output "env" {
  value = local.env
}

output "name" {
  value = local.name
}

output "path" {
  value = local.path
}

output "account_config" {
  value = local.account_config
}

output "aws" {
  value = {
    # provider
    profile             = local.aws_profile
    region              = local.aws_region
    allowed_account_ids = [local.aws_account_id]
    default_tags        = local.aws_tags

    # account
    account_name         = local.aws_account_name
    account_id           = local.aws_account_id
    account_root_iam_arn = local.aws_account_root_iam_arn
  }
}

output "aws_global" {
  value = {
    # provider
    alias               = "global"
    profile             = local.aws_profile
    region              = "us-east-1"
    allowed_account_ids = [local.aws_account_id]
    default_tags        = local.aws_tags

    # account
    account_name     = local.aws_account_name
    account_id       = local.aws_account_id
    account_root_iam_arn = local.aws_account_root_iam_arn
  }
}
