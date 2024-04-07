variable "vpc" {}
variable "ec2_key_pair" {}
variable "vpc_prefix_list" {}

variable "enable_ssh" {
  default     = false
  description = "Enable SSH access to the instances or use AWS SSM Session Manager"
}
