#!/usr/bin/env fish
kubectl --context sigsrv-sdlc create ns mattermost-operator
kubectl --context sigsrv-sdlc apply -n mattermost-operator -f https://raw.githubusercontent.com/mattermost/mattermost-operator/master/docs/mattermost-operator/mattermost-operator.yaml
