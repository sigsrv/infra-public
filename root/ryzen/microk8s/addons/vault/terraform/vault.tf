resource "consul_acl_policy" "vault" {
  name        = "vault"
  description = "https://developer.hashicorp.com/vault/docs/configuration/storage/consul#acls"

  rules = jsonencode(
    {
      "key_prefix" : {
        "vault/" : {
          "policy" : "write"
        }
      },
      "service" : {
        "vault" : {
          "policy" : "write"
        }
      },
      "agent_prefix" : {
        "" : {
          "policy" : "read"
        }
      },
      "session_prefix" : {
        "" : {
          "policy" : "write"
        }
      }
    }
  )
}

resource "consul_acl_token" "vault" {
  description = "Vault token"
  policies    = [consul_acl_policy.vault.name]
}

data "consul_acl_token_secret_id" "vault" {
  accessor_id = consul_acl_token.vault.accessor_id
}

resource "kubernetes_secret_v1" "vault" {
  metadata {
    name      = "sigsrv-infra-vault-storage-consul"
    namespace = "vault"
  }
  data = {
    CONSUL_HTTP_TOKEN = data.consul_acl_token_secret_id.vault.secret_id
  }
}
