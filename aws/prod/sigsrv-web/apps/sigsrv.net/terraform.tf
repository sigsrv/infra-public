terraform {
  cloud {
    organization = "sigsrv-prod-web"

    workspaces {
      name = "apps-sigsrv-net"
    }
  }
}
