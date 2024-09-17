#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "1password-connect" $argv
end

kubectl create secret generic \
    op-credentials \
    --from-file=1password-credentials.json=(op read "op://sigsrv-sdlc/sigsrv-sdlc-vault-op-connect/1password-credentials.json" | base64 -w 0 | psub)
