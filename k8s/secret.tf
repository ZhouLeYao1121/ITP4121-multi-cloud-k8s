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
