#!/usr/bin/env fish
function kubectl
    return command kubectl --context "sigsrv-prod" --namespace "tailscale" $argv
end

kubectl create secret generic \
    operator-oauth \
    --from-literal=client_id=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/username") \
    --from-literal=client_secret=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/password")
