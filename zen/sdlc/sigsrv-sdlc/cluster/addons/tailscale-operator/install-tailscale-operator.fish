#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "tailscale" $argv
end

kubectl create secret generic \
    operator-oauth \
    --from-literal=client_id=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/username") \
    --from-literal=client_secret=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/password")
