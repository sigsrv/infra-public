data "aws_caller_identity" "this" {}
data "aws_organizations_organization" "this" {}
data "aws_organizations_organizational_units" "workloads" {
  parent_id = one(data.aws_organizations_organization.this.roots).id
}

locals {
  root_ous = {
    for ou in data.aws_organizations_organizational_units.workloads.children : ou.name => ou
  }

  target_safe_controls = flatten(
    [
      for target_ou_name, control_names in var.enabled_safe_controls : [
        for control_name in control_names : {
          id                 = "${target_ou_name}:${var.aws_region}:${control_name}"
          target_ou_name     = target_ou_name
          target_identifier  = local.root_ous[target_ou_name].arn
          control_name       = control_name
          control_identifier = "arn:aws:controltower:${var.aws_region}::control/${control_name}"
        }
      ]
    ]
  )
}

resource "aws_controltower_control" "safe" {
  for_each = {
    for control in local.target_safe_controls : control.id => control
  }

  target_identifier  = each.value.target_identifier
  control_identifier = each.value.control_identifier
}

moved {
  from = aws_controltower_control.this
  to   = aws_controltower_control.safe
}

locals {
  target_unsafe_controls = flatten(
    [
      for target_ou_name, control_names in var.enabled_unsafe_controls : [
        for control_name, control_uid in control_names : {
          id                 = "${target_ou_name}:${var.aws_region}:${control_name}:${control_uid}"
          target_ou_name     = target_ou_name
          target_identifier  = local.root_ous[target_ou_name].arn
          control_name       = control_name
          control_uid        = control_uid
          control_identifier = "arn:aws:controltower:${var.aws_region}::control/${control_uid}"
        }
      ]
    ]
  )
}

resource "aws_controltower_control" "unsafe" {
  for_each = {
    for control in local.target_unsafe_controls : control.id => control
  }

  target_identifier  = each.value.target_identifier
  control_identifier = each.value.control_identifier
}
