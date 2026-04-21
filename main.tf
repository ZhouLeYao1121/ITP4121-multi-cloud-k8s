terraform {
  required_providers {
    azurerm = {}
    google  = {}
    kubernetes = {}
  }
}

module "azure" {
  source       = "./azure"
  azure_region = var.azure_region
  cluster_name = var.cluster_name
}

module "gcp" {
  source       = "./gcp"
  gcp_region   = var.gcp_region
  gcp_project  = var.gcp_project
  cluster_name = var.cluster_name
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "k8s" {
  source = "./k8s"
}
