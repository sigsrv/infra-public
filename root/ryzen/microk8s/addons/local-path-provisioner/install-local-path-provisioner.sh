#!/usr/bin/env bash
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.25/deploy/local-path-storage.yaml
kubectl apply -f ./local-path-storages.yaml
kubectl delete storageclass/local-path
