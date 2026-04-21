# Azure Provider Certification
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
}

# 1. Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = "multi-cloud-aks-rg"
  location = var.azure_region
}

# 2. Azure VPC (VNet)
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-private-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# 3. Strictly meets the requirement: **2 private subnets**
resource "azurerm_subnet" "aks_private_subnet_1" {
  name                 = "private-subnet-01"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "aks_private_subnet_2" {
  name                 = "private-subnet-02"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

# 4. AKS Kubernetes cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "multi-cloud-aks-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-multicloud"

  # Network configuration: Deployed within a VPC and private subnet
  network_profile {
    network_plugin = "azure"
  }

  default_node_pool {
    name           = "nodepool"
    node_count     = 2 # 2 virtual machine nodes
    vm_size        = "B2s"
    vnet_subnet_id = azurerm_subnet.aks_private_subnet_1.id

    # Basic Configuration for Cluster Auto-Scaling
    max_count = 5
    min_count = 2
  }

  # Enable Azure Log Collection (Azure Monitor Logs)
  oms_agent {
    enabled = true
  }

  # Private cluster configuration, accessible only via the internal network
  private_cluster_enabled = true
}
