#!/usr/bin/env fish
function kubectl
    return command kubectl --context "sigsrv-prod" --namespace "vault" $argv
end

kubectl create ns vault
kubectl apply -f vault.yaml
