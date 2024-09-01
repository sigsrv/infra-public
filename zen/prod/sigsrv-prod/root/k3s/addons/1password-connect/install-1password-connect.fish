#!/usr/bin/env fish
kubectl create secret generic \
    --context sigsrv-prod \
    -n 1password-connect op-credentials \
    --from-file=1password-credentials.json=(op read "op://sigsrv-prod/sigsrv-prod-vault-op-connect/1password-credentials.json" | psub)
