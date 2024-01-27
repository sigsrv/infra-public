#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns vault
kubectl --context sigsrv-sdlc apply -f vault.yaml
