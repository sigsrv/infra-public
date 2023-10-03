provider "aws" {
  profile             = module.metadata.aws.profile
  region              = module.metadata.aws.region
  allowed_account_ids = module.metadata.aws.allowed_account_ids

  default_tags {
    tags = module.metadata.aws.default_tags
  }
}

provider "aws" {
  alias               = "global"
  profile             = module.metadata.aws_global.profile
  region              = module.metadata.aws_global.region
  allowed_account_ids = module.metadata.aws_global.allowed_account_ids

  default_tags {
    tags = module.metadata.aws_global.default_tags
  }
}
