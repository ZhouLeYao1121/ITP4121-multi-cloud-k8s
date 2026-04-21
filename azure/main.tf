resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.cluster_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-aks"

  default_node_pool {
    name           = "agentpool"
    node_count     = 2
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.private1.id
  }

  identity {
    type = "SystemAssigned"
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
  }
}
