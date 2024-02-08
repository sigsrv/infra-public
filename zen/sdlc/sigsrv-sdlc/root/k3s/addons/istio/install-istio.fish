#!/usr/bin/env fish
kubectl delete helmcharts.helm.cattle.io -n kube-system traefik
kubectl delete helmcharts.helm.cattle.io -n kube-system traefik-crd
kubectl --context sigsrv-sdlc create namespace istio-system
kubectl --context sigsrv-sdlc apply -f istio-system.yaml
kubectl --context sigsrv-sdlc create namespace istio-ingress
kubectl --context sigsrv-sdlc apply -f istio-ingress.yaml
