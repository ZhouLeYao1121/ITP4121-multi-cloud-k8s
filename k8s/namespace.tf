resource "kubernetes_namespace" "app" {
  metadata { name = "wp-app" }
}
