module "metadata" {
  source = "../../modules/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

resource "aws_key_pair" "this" {
  key_name   = local.name
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/1xDlPMTREc33u5UAn/+FbvmwnsJzH6kAxTze4FLPZ EcmaXp"
}
