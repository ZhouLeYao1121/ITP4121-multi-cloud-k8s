resource "kubernetes_horizontal_pod_autoscaler" "wp" {
  metadata {
    name      = "wp-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    min_replicas = 2
    max_replicas = 5
    target {
      name = "wordpress"
      kind = "Deployment"
    }
  }
}
