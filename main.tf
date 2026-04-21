terraform {
  required_version = ">= 1.8.0"
  required_providers {
    # Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50.0"
    }
    # GCP
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0.0"
    }
    # K8s通用Provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
}

# ====================== Azure AKS 模块调用 ======================
module "azure_aks" {
  source = "./aks-to-azure"
}

# ====================== GCP GKE 模块调用 ======================
module "gcp_gke" {
  source = "./eks-to-gcp"
}
