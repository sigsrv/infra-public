#!/usr/bin/env fish
function kubectl
    command kubectl --context "sigsrv-sdlc" --namespace "mattermost-operator" $argv
end

kubectl create ns mattermost-operator
kubectl apply -f https://raw.githubusercontent.com/mattermost/mattermost-operator/master/docs/mattermost-operator/mattermost-operator.yaml
