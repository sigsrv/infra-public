terraform {
  cloud {
    organization = "sigsrv-sdlc-dev"

    workspaces {
      name = "__template__"
    }
  }
}

module "__template__" {
  source = "../../../../projects/__template__"
}

output "__template__" {
  value = module.__template__.this
}
