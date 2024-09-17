#!/usr/bin/env fish
kubectl create secret generic \
    --context sigsrv-prod \
    -n tailscale operator-oauth \
    --from-literal=client_id=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/username") \
    --from-literal=client_secret=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/password")
