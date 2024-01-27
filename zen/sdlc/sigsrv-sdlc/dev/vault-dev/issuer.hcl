path "dev/pki/sign/cockroachdb_nodes" {
    capabilities = ["create", "update"]
}

path "dev/pki/issue/cockroachdb_nodes" {
    capabilities = ["create"]
}

path "dev/pki/sign/cockroachdb_client" {
    capabilities = ["create", "update"]
}

path "dev/pki/issue/cockroachdb_client" {
    capabilities = ["create"]
}
