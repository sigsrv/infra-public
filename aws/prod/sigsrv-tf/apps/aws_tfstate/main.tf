module "tfstate_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.1"

  description             = "tfstate encryption key"
  key_usage               = "ENCRYPT_DECRYPT"
  rotation_period_in_days = 365 * 3 # = 3 years

  key_users = [for role in aws_iam_role.tfstate_role : role.arn]

  aliases = [var.kms_key_alias]

  deletion_window_in_days = 30
}

module "tfstate_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.5"

  bucket = var.s3_bucket_name

  allowed_kms_key_arn = module.tfstate_kms_key.key_arn
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.tfstate_kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

resource "aws_s3_object" "tfstate_s3_folder" {
  for_each = toset(flatten([
    for _, keys in var.s3_object_keys : keys
  ]))

  bucket       = module.tfstate_s3_bucket.s3_bucket_id
  key          = "${each.key}/"
  content_type = "application/x-directory"
}

resource "aws_dynamodb_table" "tfstate_lock_table" {
  name         = var.dynamodb_table_name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  deletion_protection_enabled = true
}

resource "aws_iam_role" "tfstate_role" {
  for_each = var.aws_accounts

  name               = "${var.iam_role_prefix}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.tfstate_role_assume[each.key].json
}

resource "aws_iam_role_policy" "tfstate_role" {
  for_each = var.aws_accounts

  name   = "${var.iam_role_prefix}-${each.key}"
  role   = aws_iam_role.tfstate_role[each.key].name
  policy = data.aws_iam_policy_document.tfstate_role[each.key].json
}

data "aws_iam_policy_document" "tfstate_role_assume" {
  for_each = var.aws_accounts

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${each.value}:root",
      ]
    }
  }
}

data "aws_iam_policy_document" "tfstate_role" {
  for_each = var.aws_accounts

  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = flatten([
      ["arn:aws:s3:::${var.s3_bucket_name}"],
      [
        for key in var.s3_object_keys[each.key] :
        "arn:aws:s3:::${var.s3_bucket_name}/${key}/*"
      ]
    ])
  }

  statement {
    sid    = "S3BucketList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = flatten([
        [""],
        [
          for key in var.s3_object_keys[each.key] : [
            [
              for i in range(1, length(split("/", key)) + 1) :
              "${join("/", slice(split("/", key), 0, i))}/"
            ],
            ["${key}/*"],
          ]
        ],
      ])
    }
  }

  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      aws_dynamodb_table.tfstate_lock_table.arn,
    ]
  }
}
