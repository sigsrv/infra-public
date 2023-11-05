#!/usr/bin/env bash
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=ke5f4h6CNTRL \
  --from-literal=client_secret=`pbpaste`
