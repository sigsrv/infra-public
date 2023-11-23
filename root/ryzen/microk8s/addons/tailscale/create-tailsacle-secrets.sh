#!/usr/bin/env bash
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=ku9Q2q5CNTRL \
  --from-literal=client_secret=`pbpaste`
