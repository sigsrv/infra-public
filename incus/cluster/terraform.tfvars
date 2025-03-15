networks = {
  "incusbr0" : {
    parent    = "incus0"
    ipv4_cidr = "172.16.0.0/16"
    zone      = "incus.local"
  }
  "sigsrvbr0" : {
    parent    = "sigsrv0"
    ipv4_cidr = "172.20.0.0/16"
    zone      = "sigsrv.local"
  }
}
