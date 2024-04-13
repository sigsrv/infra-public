#!/usr/bin/env fish
helm upgrade \
  --install \
  --kube-context sigsrv-sdlc \
  tailscale-operator \
  tailscale/tailscale-operator \
  --namespace=tailscale \
  --create-namespace \
  --set-string oauth.clientId=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/username") \
  --set-string oauth.clientSecret=(op read "op://sigsrv-sdlc/sigsrv-sdlc-tailscale-operator/password") \
  --set-string 'operatorConfig.hostname=sigsrv-sdlc-tailscale-operator' \
  --set 'operatorConfig.defaultTags={tag:sigsrv-sdlc-tailscale-operator}' \
  --set-string 'proxyConfig.defaultTags=tag:sigsrv-sdlc-tailscale-service' \
  --set-string 'proxyConfig.apiServerProxyConfig.mode=true' \
  --wait
