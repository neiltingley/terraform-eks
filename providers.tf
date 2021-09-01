terraform {
  required_providers {
    random = {
      version = "~> 2.1"
    }
    local = {
      version = "~> 1.2"
    }
    null = {
      version = ">= 2.1"
    }
    template = {
      version = ">= 2.1"
    }
    aws = {
      version = ">= 3.56.0"
    }
    helm = {
      version =">= 2.3.0"
    }
  }
}
