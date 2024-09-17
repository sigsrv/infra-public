#!/usr/bin/env fish
kubectl create secret generic \
    --context sigsrv-sdlc \
    -n tailscale operator-oauth \
    --from-literal=client_id=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/username") \
    --from-literal=client_secret=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/password")
