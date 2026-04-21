resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private1" {
  name          = "private-subnet-1"
  ip_cidr_range = "10.1.1.0/24"
  network       = google_compute_network.vpc.name
  region        = var.gcp_region
}

resource "google_compute_subnetwork" "private2" {
  name          = "private-subnet-2"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.vpc.name
  region        = var.gcp_region
}
