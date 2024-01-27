#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns tailscale

# https://login.tailscale.com/admin/settings/oauth
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/username") \
  --from-literal=client_secret=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/password")

kubectl --context sigsrv-sdlc apply -f tailscale.yaml
