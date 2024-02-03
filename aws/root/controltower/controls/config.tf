variable "aws_profile" {
  type    = string
  default = "sso-sigsrv-root"
}

variable "aws_account_id" {
  type    = string
  default = "607292096646" # sigsrv
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "enabled_safe_controls" {
  type = map(list(string))
  default = {
    "Sandbox" : [
      "AWS-GR_DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS",
      "AWS-GR_EBS_OPTIMIZED_INSTANCE",
      "AWS-GR_EC2_VOLUME_INUSE_CHECK",
      "AWS-GR_ENCRYPTED_VOLUMES",
      "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
      "AWS-GR_RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
      "AWS-GR_RDS_STORAGE_ENCRYPTED",
      "AWS-GR_RESTRICTED_COMMON_PORTS",
      "AWS-GR_RESTRICTED_SSH",
      "AWS-GR_RESTRICT_ROOT_USER",
      "AWS-GR_RESTRICT_ROOT_USER_ACCESS_KEYS",
      "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED",
      "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED",
      "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    ],
    "Workloads" : [
      "AWS-GR_DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS",
      "AWS-GR_EBS_OPTIMIZED_INSTANCE",
      "AWS-GR_EC2_VOLUME_INUSE_CHECK",
      "AWS-GR_ENCRYPTED_VOLUMES",
      "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
      "AWS-GR_RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
      "AWS-GR_RDS_STORAGE_ENCRYPTED",
      "AWS-GR_RESTRICTED_COMMON_PORTS",
      "AWS-GR_RESTRICTED_SSH",
      "AWS-GR_RESTRICT_ROOT_USER",
      "AWS-GR_RESTRICT_ROOT_USER_ACCESS_KEYS",
      "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED",
      "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED",
      "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    ],
  }
}

//noinspection SpellCheckingInspection
variable "enabled_unsafe_controls" {
  type = map(map(string))
  //noinspection TFIncorrectVariableType
  default = {
    "Sandbox" : {
      # "CT.CLOUDFORMATION.PR.1" : "AZAYRJYXCXZR",
      # "CT.CLOUDFRONT.PR.1" : "VBJDOHQSIIAX",
      # "CT.CODEBUILD.PR.1" : "XWOSMSCORYXY",
      # "CT.CODEBUILD.PR.2" : "EOOPASTMJSET",
      # "CT.DMS.PR.1" : "PMXDPOCYQXVY",
      # "CT.EC2.PR.4" : "YTLKASXYASWH",
      # "CT.LAMBDA.PR.2" : "LNBOCFPQISPJ",
      # "CT.OPENSEARCH.PR.10" : "XRNYJUFPDRET",
      # "CT.OPENSEARCH.PR.2" : "UCLVYXAVOAHM",
      # "CT.RDS.PR.23" : "NNNWMZYHHRLE",
      # "CT.REDSHIFT.PR.1" : "XOLIHOFJYQAC",
      # "SH.CodeBuild.1" : "TIHGQHSIUQES",
      # "SH.CodeBuild.2" : "IHLKDRJWXUHX",
      # "SH.DMS.1" : "KKTKHLMBCETI",
      # "SH.EC2.1" : "OSTTYXVZPAKB",
      # "SH.EC2.19" : "VHSRRHUYSMZF",
      # "SH.ES.2" : "TPVVQKJODFVL",
      # "SH.IAM.4" : "KNDGXYOAJBAD",
      # "SH.IAM.6" : "BOIRCXQEYNLQ",
      # "SH.KMS.3" : "IRPUDLZBQQWO",
      # "SH.Lambda.1" : "FQMQXEDYMYNK",
      # "SH.Opensearch.2" : "NPHMMQWTNQJA",
      # "SH.RDS.1" : "JZXYYUXYDVES",
      # "SH.RDS.2" : "LVCJBGBIVJAD",
      # "SH.Redshift.1" : "KUKRAWPCWPWD",
      # "SH.S3.2" : "JVTGANIDGRYD",
      # "SH.S3.3" : "UQFGRBNKRVKM",
      # "SH.SSM.4" : "UDAQAMUOGDDV",
    },
    "Workloads" : {
      # "CT.CLOUDFORMATION.PR.1" : "AZAYRJYXCXZR",
      # "CT.CLOUDFRONT.PR.1" : "VBJDOHQSIIAX",
      # "CT.CODEBUILD.PR.1" : "XWOSMSCORYXY",
      # "CT.CODEBUILD.PR.2" : "EOOPASTMJSET",
      # "CT.DMS.PR.1" : "PMXDPOCYQXVY",
      # "CT.EC2.PR.4" : "YTLKASXYASWH",
      # "CT.LAMBDA.PR.2" : "LNBOCFPQISPJ",
      # "CT.OPENSEARCH.PR.10" : "XRNYJUFPDRET",
      # "CT.OPENSEARCH.PR.2" : "UCLVYXAVOAHM",
      # "CT.RDS.PR.23" : "NNNWMZYHHRLE",
      # "CT.REDSHIFT.PR.1" : "XOLIHOFJYQAC",
      # "SH.CodeBuild.1" : "TIHGQHSIUQES",
      # "SH.CodeBuild.2" : "IHLKDRJWXUHX",
      # "SH.DMS.1" : "KKTKHLMBCETI",
      # "SH.EC2.1" : "OSTTYXVZPAKB",
      # "SH.EC2.19" : "VHSRRHUYSMZF",
      # "SH.ES.2" : "TPVVQKJODFVL",
      # "SH.IAM.4" : "KNDGXYOAJBAD",
      # "SH.IAM.6" : "BOIRCXQEYNLQ",
      # "SH.KMS.3" : "IRPUDLZBQQWO",
      # "SH.Lambda.1" : "FQMQXEDYMYNK",
      # "SH.Opensearch.2" : "NPHMMQWTNQJA",
      # "SH.RDS.1" : "JZXYYUXYDVES",
      # "SH.RDS.2" : "LVCJBGBIVJAD",
      # "SH.Redshift.1" : "KUKRAWPCWPWD",
      # "SH.S3.2" : "JVTGANIDGRYD",
      # "SH.S3.3" : "UQFGRBNKRVKM",
      # "SH.SSM.4" : "UDAQAMUOGDDV"
    },
  }
}
