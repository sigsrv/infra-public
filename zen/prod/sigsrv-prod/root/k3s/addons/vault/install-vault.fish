#!/usr/bin/env fish
kubectl --context sigsrv-prod create ns vault
kubectl --context sigsrv-prod apply -f vault.yaml
