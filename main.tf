terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3.0"
    }
  }
}
provider "kubernetes" {
  config_path = "./kubeconfig.yaml"
}
provider "helm" {
  kubernetes {
    config_path = "./kubeconfig.yaml"
  }
}




