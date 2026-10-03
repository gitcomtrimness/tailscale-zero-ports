terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.21"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Reads TAILSCALE_API_KEY from the environment.
# "-" means "the tailnet this key belongs to".
provider "tailscale" {
  tailnet = "-"
}