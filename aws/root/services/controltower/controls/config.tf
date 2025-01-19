variable "aws_profile" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "enabled_safe_controls" {
  type = map(list(string))
}

//noinspection SpellCheckingInspection
variable "enabled_unsafe_controls" {
  type = map(map(string))
}
