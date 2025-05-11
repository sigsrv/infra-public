terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.2.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.1"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.20.0"
    }
  }
}

provider "incus" {
  remote {
    name    = "sigsrv"
    scheme  = "https"
    address = "sigsrv.deer-neon.ts.net"
    default = true
  }
}

provider "onepassword" {
  account = "my.1password.com"
}

data "onepassword_item" "tailscale" {
  vault = "sigsrv-prod"
  title = "sigsrv-incus-network-tailscale"
}

provider "tailscale" {
  tailnet             = "ecmaxp.kr"
  oauth_client_id     = data.onepassword_item.tailscale.username
  oauth_client_secret = data.onepassword_item.tailscale.password
}
