#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns container-registry
kubectl --context sigsrv-sdlc apply -f registry.yaml
