#!/usr/bin/env bash
# https://login.tailscale.com/admin/settings/oauth
kubectl create secret generic operator-oauth \
  -n tailscale \
  --from-literal=client_id=kxKajA7CNTRL \
  --from-literal=client_secret=`pbpaste`
