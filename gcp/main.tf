resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_container_cluster" "gke" {
  name     = "${var.cluster_name}-gke"
  location = var.gcp_region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private1.name

  remove_default_node_pool = true
  initial_node_count       = 1

  autoscaling_profile = "BALANCED"

  depends_on = [google_project_service.compute, google_project_service.container]
}

resource "google_container_node_pool" "nodes" {
  name     = "pool"
  location = google_container_cluster.gke.location
  cluster  = google_container_cluster.gke.name

  node_count = 2

  node_config {
    machine_type = "e2-medium"
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }
}
