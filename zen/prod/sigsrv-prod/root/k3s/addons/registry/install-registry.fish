#!/usr/bin/env fish
kubectl --context sigsrv-prod create ns container-registry
kubectl --context sigsrv-prod apply -f registry.yaml
