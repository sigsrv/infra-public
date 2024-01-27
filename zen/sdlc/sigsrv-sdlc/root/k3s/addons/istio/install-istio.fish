#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create namespace istio-system
kubectl --context sigsrv-sdlc apply -f istio-system.yaml
kubectl --context sigsrv-sdlc create namespace istio-ingress
kubectl --context sigsrv-sdlc apply -f istio-ingress.yaml
