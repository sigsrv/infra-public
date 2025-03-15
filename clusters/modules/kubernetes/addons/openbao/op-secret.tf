data "kubernetes_secret" "machine_init" {
  metadata {
    name      = "${helm_release.this.name}-init"
    namespace = helm_release.this.namespace
  }

  depends_on = [
    kubernetes_job.init,
  ]
}

data "onepassword_vault" "vault" {
  name = var.onepassword.vault_name
}

locals {
  machine_init  = sensitive(jsondecode(data.kubernetes_secret.machine_init.data["machine-init.json"]))
  op_secret_uri = "op://${var.onepassword.vault_name}/${var.kubernetes.cluster_name}-openbao"
  op_secret_uris = {
    encrypted_unseal_keys = "${local.op_secret_uri}/encrypted-unseal-keys"
    encrypted_root_token  = "${local.op_secret_uri}/encrypted-root-token/root-token"
    unseal_command        = "${local.op_secret_uri}/openbao-commands/unseal"
  }
}

resource "onepassword_item" "this" {
  vault = data.onepassword_vault.vault.uuid
  title = "${var.kubernetes.cluster_name}-openbao"

  section {
    label = "encrypted-unseal-keys"

    dynamic "field" {
      for_each = local.machine_init.unseal_keys_b64

      content {
        label = "key-${field.key}"
        type  = "CONCEALED"
        value = field.value
      }
    }
  }

  section {
    label = "encrypted-root-token"

    field {
      label = "root-token"
      type  = "CONCEALED"
      value = local.machine_init.root_token
    }
  }

  section {
    label = "openbao-commands"

    field {
      label = "decrypt-root-token"
      value = trimspace(<<EOF
export BAO_TOKEN=(op read "${local.op_secret_uris.encrypted_root_token}" | base64 -d | gpg --decrypt)
EOF
      )
    }

    field {
      label = "unseal-alias"
      value = trimspace(<<EOF
op read "${local.op_secret_uris.unseal_command}" | tee /dev/stderr | source
EOF
      )
    }

    field {
      label = "unseal"
      value = trimspace(<<EOF
function __bao_operator_unseal
  set -l ENCRYPTED_UNSEAL_KEYS
  for i in (seq 0 ${length(local.machine_init.unseal_keys_b64) - 1})
      set -a ENCRYPTED_UNSEAL_KEYS (op read "${local.op_secret_uris.encrypted_unseal_keys}/key-$i")
  end

  for i in (seq 0 ${var.openbao.replicas - 1})
    for encrypted_unseal_key in $ENCRYPTED_UNSEAL_KEYS
      kubectl exec -n openbao openbao-$i -c openbao -- \
        bao operator unseal (echo $encrypted_unseal_key | base64 -d | gpg --decrypt)
    end
  end
end

__bao_operator_unseal
functions -e __bao_operator_unseal
EOF
      )
    }
  }

  tags = var.onepassword.tags
}
