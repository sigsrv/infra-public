resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("${path.module}/admin-policy.hcl")
}

resource "null_resource" "admin" {
  depends_on = [vault_policy.admin]

  provisioner "local-exec" {
    command = "vault write auth/userpass/users/admin policies=admin password=`op read op://sigsrv-sdlc/sigsrv-sdlc-vault-admin/password`"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "vault delete auth/userpass/users/admin"
  }
}
