locals {
  package_path = abspath(path.root)
  package_name = basename(local.package_path)

  account_config_path = "${dirname(local.package_path)}/account.yaml"
  account_config      = yamldecode(file(local.account_config_path))

  aws_account_id   = local.account_config["aws_account_id"]
  aws_account_name = local.account_config["aws_account_name"]
  aws_region       = local.account_config["aws_region"]
  aws_profile      = local.account_config["aws_profile"]

  aws_account_root_iam_arn = "arn:aws:iam::${local.aws_account_id}:root"

  aws_tags = {
    "sigsrv:terraform"   = "true"
    "sigsrv:workspace"   = local.name
    "sigsrv:application" = local.name
    "sigsrv:namespace"   = local.namespace
    "sigsrv:account"     = local.aws_account_name
    "sigsrv:env"         = local.env
    "sigsrv:package"     = local.package_name
    "sigsrv:name"        = local.name
  }
}

locals {
  namespace = local.account_config["namespace"]
  account   = local.aws_account_name
  env       = local.account_config["env"]
  package   = local.package_name

  name = (
  strcontains(local.account, local.env)
  ? "${local.account}-${local.package_name}"
  : "${local.account}-${local.env}-${local.package_name}"
  )

  path = (
  strcontains(local.account, local.env)
  ? "${local.account}/${local.package_name}"
  : "${local.account}/${local.env}/${local.package_name}"
  )
}
