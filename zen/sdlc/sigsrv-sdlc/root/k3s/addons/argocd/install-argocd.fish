#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns argocd
kubectl --context sigsrv-sdlc apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=stable"
kubectl --context sigsrv-sdlc apply -f argocd.yaml
