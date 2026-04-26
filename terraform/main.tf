terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Verify Docker is accessible
data "docker_version" "current" {}

# Output Terraform and Docker versions for validation
output "terraform_version" {
  value = terraform.version
}

output "docker_version" {
  value = data.docker_version.current.version
}

# This file establishes the foundation for Infrastructure as Code (IaC)
# 
# Current setup supports:
# - Local docker-compose based development
# - Docker provider for terraform-managed resources
#
# For production deployment, consider:
# - AWS, GCP, or Azure providers
# - Kubernetes provider
# - Cloud-specific networking/vpc modules
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply