#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-prod" --namespace "rook-ceph" $argv
end

kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.15/deploy/examples/crds.yaml
