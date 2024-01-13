#!/usr/bin/env fish
kubectl --context sigsrv-prod create ns mattermost-operator
kubectl --context sigsrv-prod apply -n mattermost-operator -f https://raw.githubusercontent.com/mattermost/mattermost-operator/master/docs/mattermost-operator/mattermost-operator.yaml
