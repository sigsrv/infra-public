## https://support.hashicorp.com/hc/en-us/articles/17843632998163-Troubleshoot-Consul-ACL-issues
#
#locals {
#  microk8s_nodes = [
#    "microk8s-worker-0",
#    "microk8s-worker-1",
#    "microk8s-worker-2",
#  ]
#}
#
#resource "consul_acl_token" "microk8s-worker-consul-agent" {
#  description = "microk8s-worker-* agent token"
#  policies    = []
#
#  dynamic "node_identities" {
#    for_each = toset(local.microk8s_nodes)
#    content {
#      datacenter = "dc1"
#      node_name  = node_identities.key
#    }
#  }
#}
#
#data "consul_acl_token_secret_id" "microk8s-worker-consul-agent" {
#  accessor_id = consul_acl_token.microk8s-worker-consul-agent.accessor_id
#}
#
#resource "kubernetes_secret_v1" "microk8s-worker-consul-agent" {
#  metadata {
#    name      = "sigsrv-infra-microk8s-worker-consul-agent"
#    namespace = "vault"
#  }
#  data = {
#    CONSUL_HTTP_TOKEN = data.consul_acl_token_secret_id.microk8s-worker-consul-agent.secret_id
#  }
#}
