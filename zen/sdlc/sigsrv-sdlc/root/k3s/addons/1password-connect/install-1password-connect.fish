#!/usr/bin/env fish
kubectl create secret generic \
    --context sigsrv-sdlc \
    -n 1password-connect op-credentials \
    --from-file=1password-credentials.json=(op read "op://sigsrv-sdlc/sigsrv-sdlc-vault-op-connect/1password-credentials.json" | psub)
