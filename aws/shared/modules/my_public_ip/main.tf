data "http" "my_public_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  my_public_ip = (
    data.http.my_public_ip.status_code == 200
    ? trimspace(data.http.my_public_ip.response_body)
    : null
  )

  my_public_ip_cidr = "${local.my_public_ip}/32"
}
