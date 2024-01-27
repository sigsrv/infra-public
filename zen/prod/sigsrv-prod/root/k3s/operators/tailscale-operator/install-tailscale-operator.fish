#!/usr/bin/env fish
kubectl --context sigsrv-prod create ns tailscale

# https://login.tailscale.com/admin/settings/oauth
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/username") \
  --from-literal=client_secret=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/password")

kubectl --context sigsrv-prod apply -f tailscale.yaml
