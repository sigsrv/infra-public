variable "aws_accounts" {
  type = map(string)
}

variable "kms_key_alias" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_object_keys" {
  type = map(list(string))
}

variable "dynamodb_table_name" {
  type = string
}

variable "iam_role_prefix" {
  type = string
}
