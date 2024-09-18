#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "vault" $argv
end

kubectl create ns vault
kubectl apply -f vault.yaml
