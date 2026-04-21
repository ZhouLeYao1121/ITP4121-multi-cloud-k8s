terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "azure_region" {
  type    = string
  default = "eastasia"
}

variable "gcp_region" {
  type    = string
  default = "asia-east1"
}

variable "gcp_project" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "itp4121-single"
}

# ====================== Azure 完整资源 =========================
resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_name}-rg"
  location = var.azure_region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "private1" {
  name                 = "private-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private2" {
  name                 = "private-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.cluster_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-aks"

  default_node_pool {
    name       = "agentpool"
    node_count = 2
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

# ====================== GCP 完整资源（已补全所有必填字段，解决本次报错） =========================
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project
}

resource "google_compute_subnetwork" "private1" {
  name          = "private-subnet-1"
  ip_cidr_range = "10.1.1.0/24"
  network       = google_compute_network.vpc.name
  region        = var.gcp_region
  project       = var.gcp_project
}

resource "google_compute_subnetwork" "private2" {
  name          = "private-subnet-2"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.vpc.name
  region        = var.gcp_region
  project       = var.gcp_project
}

resource "google_container_cluster" "gke" {
  name     = "${var.cluster_name}-gke"
  location = var.gcp_region
  project  = var.gcp_project

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private1.name

  remove_default_node_pool = true
  initial_node_count       = 1

  # 【核心修复：强制补齐features必填块，直接解决本次报错】
  features {}

  depends_on = [google_project_service.compute, google_project_service.container]
}

resource "google_container_node_pool" "nodes" {
  name     = "pool"
  location = google_container_cluster.gke.location
  cluster  = google_container_cluster.gke.name
  project  = var.gcp_project

  node_count = 2
  node_config {
    machine_type = "e2-medium"
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}
