#!/usr/bin/env fish

# init plugin
vault plugin register -sha256=8eb865ca4ac9c7c87fa902985383da0132462f299765752f74e6f212e796a5bd secret op-connect

# setup cerd
op read "op://sigsrv/sigsrv Credentials File/1password-credentials.json" | base64 | tr -d '\n' > 1password-credentials.json
vault kv put -cas 8 sigsrv-k3s/secret/addons/1password/op-credentials 1password-credentials.json=@1password-credentials.json
rm 1password-credentials.json

vault kv put -cas 0 sigsrv-k3s/secret/addons/1password/onepassword-token token=(op read "op://sigsrv/w3jh22mghxtpwmdmveiogdk77y/credential")

#
vault secrets enable --path="sigsrv-k3s/op" op-connect
vault write sigsrv-k3s/op/config op_connect_host=http://onepassword-connect.1password-sigsrv-k3s.svc.cluster.local:8080 \
    op_connect_token=(vault kv get -field=token sigsrv-k3s/secret/addons/1password/onepassword-token)
