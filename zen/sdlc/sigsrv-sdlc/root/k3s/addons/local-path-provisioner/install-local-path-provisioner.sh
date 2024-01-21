#!/usr/bin/env bash
# https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.25/deploy/local-path-storage.yaml
kubectl apply -f ./local-path-storages.yaml
kubectl delete storageclass/local-path
