#!/usr/bin/env fish
# https://login.tailscale.com/admin/settings/oauth
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=(op read "op://Personal/sigsrv-k3s-tailscale-operator/username") \
  --from-literal=client_secret=(op read "op://Personal/sigsrv-k3s-tailscale-operator/password")
