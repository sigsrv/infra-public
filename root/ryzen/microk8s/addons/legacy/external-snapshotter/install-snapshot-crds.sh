#!/usr/bin/env bash

# https://github.com/kubernetes-csi/external-snapshotter/tree/master#usage
# https://github.com/kubernetes-csi/external-snapshotter/tree/master/client/config/crd
kubectl kustomize crd | kubectl create -f -
