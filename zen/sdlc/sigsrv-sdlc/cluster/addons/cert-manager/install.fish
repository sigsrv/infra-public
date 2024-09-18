#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "cert-manager" $argv
end

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
