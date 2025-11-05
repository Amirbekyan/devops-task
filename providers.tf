terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.19.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }

    # random = {
    #   source  = "hashicorp/random"
    #   version = ">= 3.4.3"
    # }
  }
}

provider "kubernetes" {
  config_path = "/root/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "/root/.kube/config"
  }
}
