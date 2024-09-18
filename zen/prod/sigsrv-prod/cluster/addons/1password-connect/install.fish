#!/usr/bin/env fish
function kubectl
    return command kubectl --context "sigsrv-prod" --namespace "1password-connect" $argv
end

kubectl create secret generic \
    op-credentials \
    --from-file=1password-credentials.json=(op read "op://sigsrv-prod/sigsrv-prod-vault-op-connect/1password-credentials.json" | base64 -w 0 | psub)
