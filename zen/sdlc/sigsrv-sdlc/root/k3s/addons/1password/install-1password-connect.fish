#!/usr/bin/env fish
export VAULT_ADDR https://vault.deer-neon.ts.net
set OP_1PASSWORD_CREDENTIALS_FILE_PATH "op://sigsrv-sdlc/sigsrv-sdlc Credentials File/1password-credentials.json"
set OP_1PASSWORD_TOKEN_FILE_PATH "op://sigsrv-sdlc/cc4v2etvvreibzei4agjsghaxq/credential"

# init plugin
vault plugin register -sha256=8eb865ca4ac9c7c87fa902985383da0132462f299765752f74e6f212e796a5bd secret op-connect

# setup cerd
op read $OP_1PASSWORD_CREDENTIALS_FILE_PATH | base64 | tr -d '\n' > 1password-credentials.json
vault kv put -cas 8 secret/addons/1password/op-credentials 1password-credentials.json=@1password-credentials.json
rm 1password-credentials.json

vault kv put -cas 0 secret/addons/1password/onepassword-token token=(op read $OP_1PASSWORD_TOKEN_FILE_PATH)

# setup op
vault secrets enable --path="op" op-connect
vault write op/config \
    op_connect_host=http://onepassword-connect.1password-sigsrv-k3s.svc.cluster.local:8080 \
    op_connect_token=(vault kv get -field=token secret/addons/1password/onepassword-token)
