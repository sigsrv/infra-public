kms_key_alias       = "sigsrv-infra-tfstate-kms-key"
iam_role_prefix     = "sigsrv-infra-tfstate"
s3_bucket_name      = "sigsrv-infra-tfstate"
dynamodb_table_name = "sigsrv-infra-tfstate-lock"

aws_accounts = {
  # prod
  "sigsrv-workloads-prod-nas" = "428959989222"
  "sigsrv-workloads-prod-net" = "466090905152"
  "sigsrv-workloads-prod-web" = "058264144717"
  # sdlc
  "sigsrv-workloads-sdlc" = "113283726464"
}

s3_object_keys = {
  # prod
  "sigsrv-workloads-prod-nas" = [
    "test/prod/sigsrv-nas",
    "aws/prod/sigsrv-nas",
  ]
  "sigsrv-workloads-prod-net" = [
    "test/prod/sigsrv-net",
    "aws/prod/sigsrv-net",
    "clusters/prod",
    "clusters/shared",
    "users",
  ]
  "sigsrv-workloads-prod-web" = [
    "test/prod/sigsrv-web",
    "aws/prod/sigsrv-web",
  ]
  # sdlc
  "sigsrv-workloads-sdlc" = [
    "test/sdlc/sigsrv-dev",
    "aws/sdlc/sigsrv-dev",
    "clusters/sdlc",
  ]
}
