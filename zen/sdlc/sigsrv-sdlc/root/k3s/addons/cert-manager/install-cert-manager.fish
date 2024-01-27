#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns cert-manager
kubectl --context sigsrv-sdlc apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
kubectl --context sigsrv-sdlc apply -f cert-manager.yaml
kubectl --context sigsrv-sdlc apply -f trust-manager.yaml
