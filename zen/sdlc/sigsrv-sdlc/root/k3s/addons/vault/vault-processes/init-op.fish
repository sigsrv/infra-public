#!/usr/bin/env fish
export VAULT_ADDR="https://vault-sdlc.deer-neon.ts.net"
set --unpath OP_1PASSWORD_TOKEN_PATH "op://sigsrv-sdlc/sigsrv-sdlc-vault-op/credential"

# init plugin
vault plugin register -sha256=8eb865ca4ac9c7c87fa902985383da0132462f299765752f74e6f212e796a5bd secret op-connect

# setup cerd
vault kv put -cas 0 secret/addon/1password/onepassword-token token=(op read $OP_1PASSWORD_TOKEN_PATH)

# setup op
vault secrets enable --path="op" op-connect
vault write op/config \
    op_connect_host=http://onepassword-connect.1password.svc.cluster.local:8080 \
    op_connect_token=(vault kv get -field=token secret/addon/1password/onepassword-token)
