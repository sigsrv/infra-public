kms_key_alias       = "sigsrv-infra-tfstate-kms-key"
iam_role_prefix     = "sigsrv-infra-tfstate"
s3_bucket_name      = "sigsrv-infra-tfstate"
dynamodb_table_name = "sigsrv-infra-tfstate-lock"

aws_accounts = {
  # root
  "sigsrv-root" = "607292096646"
  # prod
  "sigsrv-workloads-prod-nas" = "428959989222"
  "sigsrv-workloads-prod-net" = "466090905152"
  "sigsrv-workloads-prod-tf"  = "820242943905"
  "sigsrv-workloads-prod-web" = "058264144717"
  # sdlc
  "sigsrv-workloads-sdlc" = "113283726464"
}

s3_object_keys = {
  # root
  "sigsrv-root" = [ # sigsrv-root
    "test/root/sigsrv-root",
    "aws/root",
  ]
  # prod
  "sigsrv-workloads-prod-nas" = [ # sigsrv-nas
    "test/prod/sigsrv-nas",
    "aws/prod/sigsrv-nas",
  ]
  "sigsrv-workloads-prod-net" = [ # sigsrv-net
    "test/prod/sigsrv-net",
    "aws/prod/sigsrv-net",
    "clusters/prod",
    "clusters/shared",
    "github/sigsrv",
    "users",
  ]
  "sigsrv-workloads-prod-tf" = [ # sigsrv-tf
    "test/prod/sigsrv-tf",
    "aws/prod/sigsrv-tf",
  ]
  "sigsrv-workloads-prod-web" = [ # sigsrv-web
    "test/prod/sigsrv-web",
    "aws/prod/sigsrv-web",
  ]
  # sdlc
  "sigsrv-workloads-sdlc" = [ # sigsrv-sdlc
    "test/sdlc/sigsrv-dev",
    "aws/sdlc/sigsrv-dev",
    "clusters/sdlc",
  ]
}
