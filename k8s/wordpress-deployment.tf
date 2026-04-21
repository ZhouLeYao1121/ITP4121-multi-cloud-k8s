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
