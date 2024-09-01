locals {
  app_roles = {
    "langbot/langbot-openai" = {
      "op/vaults/sigsrv-prod/items/sigsrv-prod-langbot-secrets-openai" = ["read"]
    }
    "langbot/langbot-claude" = {
      "op/vaults/sigsrv-prod/items/sigsrv-prod-langbot-secrets-claude" = ["read"]
    }
    "langbot/langbot-gemini" = {
      "op/vaults/sigsrv-prod/items/sigsrv-prod-langbot-secrets-gemini" = ["read"]
    }
  }
}

locals {
  all_app_roles = {
    for name, policies in local.app_roles : name => {
      role = "app-${replace(name, "/", "-")}"
      service_account = {
        names     = [split("/", name)[1]]
        namespace = [split("/", name)[0]]
      }
      policies = {
        for path, capabilities in policies : path => {
          path         = path
          capabilities = capabilities
        }
      }
    }
  }
}

resource "vault_kubernetes_auth_backend_role" "this" {
  for_each = local.all_app_roles

  backend                          = "kubernetes"
  role_name                        = each.value.role
  bound_service_account_names      = each.value.service_account.names
  bound_service_account_namespaces = each.value.service_account.namespace
  token_policies                   = [vault_policy.this[each.key].name]
}

resource "vault_policy" "this" {
  for_each = local.all_app_roles

  name   = "app/${each.key}"
  policy = data.vault_policy_document.this[each.key].hcl
}

data "vault_policy_document" "this" {
  for_each = local.all_app_roles

  dynamic "rule" {
    for_each = each.value.policies

    content {
      path         = rule.value.path
      capabilities = rule.value.capabilities
    }
  }
}
