#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns postgres-operator
kubectl --context sigsrv-sdlc apply -f postgres-operator.yaml
