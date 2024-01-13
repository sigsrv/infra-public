#!/usr/bin/env fish
kubectl --context sigsrv-sdlc apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/install/crds.yaml
kubectl --context sigsrv-sdlc apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/install/operator.yaml
