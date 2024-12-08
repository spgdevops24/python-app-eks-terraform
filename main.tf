provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

locals {
  app_name  = var.app_name
}