#!/usr/bin/env fish
function kubectl
    return command kubectl --context "sigsrv-prod" --namespace "argocd" $argv
end

kubectl create ns argocd
kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=stable"
kubectl apply -f argocd.yaml

argocd login \
    --name sigsrv-prod \
    argocd-prod.deer-neon.ts.net \
    --username admin \
    --password (kubectl view-secret argocd-initial-admin-secret password -q)

curl "https://keybase.io/ecmaxp/pgp_keys.asc" > pgp_keys.asc
argocd gpg add --from pgp_keys.asc
rm -f pgp_keys.asc

set OP_ARGOCD_SSH_SECRET "op://sigsrv-prod/sigsrv-prod-argocd-ssh/private_key"
op read $OP_ARGOCD_SSH_SECRET  > /tmp/argocd-ssh.key
argocd repo add \
    --name sigsrv-infra \
    --project default \
    --ssh-private-key-path=/tmp/argocd-ssh.key \
    git@github.com:sigsrv/infra.git
rm -f /tmp/argocd-ssh.key

kubectl apply -f argocd-cluster.yaml
