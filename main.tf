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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# ===================== 全局变量 =====================
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

# ===================== Azure 多云资源 =====================
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

# ===================== GCP 多云资源 =====================
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
    max_node_count = 4
  }
}

# ===================== K8s 集群连接配置 =====================
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# ===================== K8s 全部作业资源（全语法修复） =====================
resource "kubernetes_namespace" "app" {
  metadata {
    name = "wp-app"
  }
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  data = {
    password = "Pass123456"
    user     = "wpuser"
  }
  type = "Opaque"
}

# MySQL 无头服务（修复StatefulSet必填service_name）
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = { app = "mysql" }
    cluster_ip = "None"
    port {
      port = 3306
    }
  }
}

resource "kubernetes_stateful_set" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    service_name = kubernetes_service.mysql.metadata[0].name
    replicas = 1
    selector {
      match_labels = { app = "mysql" }
    }
    template {
      metadata { labels = { app = "mysql" } }
      spec {
        container {
          image = "mysql:5.6"
          name  = "mysql"
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "password"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "wp" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    replicas = 2
    selector { match_labels = { app = "wp" } }
    template {
      metadata { labels = { app = "wp" } }
      spec {
        container {
          image = "wordpress:latest"
          name  = "wordpress"
        }
      }
    }
  }
}

# WordPress Service 【完全修复端口语法报错】
resource "kubernetes_service" "wp" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = { app = kubernetes_deployment.wp.spec[0].selector[0].match_labels.app }
    port {
      port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "wp" {
  metadata {
    name      = "wp-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = { "ssl-redirect" = "true" }
  }
  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.wp.metadata[0].name
              port {
                port = 80
              }
            }
          }
        }
      }
    }
  }
}

# HPA 自动扩缩容 【完全修复新版scale_target_ref语法报错】
resource "kubernetes_horizontal_pod_autoscaler" "wp" {
  metadata {
    name      = "wp-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    min_replicas = 2
    max_replicas = 5

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.wp.metadata[0].name
    }
  }
}
