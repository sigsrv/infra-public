#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create namespace istio-system
kubectl --context sigsrv-sdlc apply -f istio-system.yaml
