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
              name = "wordpress"
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}
