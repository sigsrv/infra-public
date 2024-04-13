#!/usr/bin/env fish
helm upgrade \
  --install \
  --kube-context sigsrv-prod \
  tailscale-operator \
  tailscale/tailscale-operator \
  --namespace=tailscale \
  --create-namespace \
  --set-string oauth.clientId=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/username") \
  --set-string oauth.clientSecret=(op read "op://sigsrv-prod/sigsrv-prod-tailscale-operator/password") \
  --set-string 'operatorConfig.hostname=sigsrv-prod-tailscale-operator' \
  --set 'operatorConfig.defaultTags={tag:sigsrv-prod-tailscale-operator}' \
  --set-string 'proxyConfig.defaultTags=tag:sigsrv-prod-tailscale-service' \
  --set-string 'proxyConfig.apiServerProxyConfig.mode=true' \
  --wait
