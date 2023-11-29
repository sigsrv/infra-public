#!/usr/bin/env bash
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=kSEoeK5CNTRL \
  --from-literal=client_secret=`pbpaste`
