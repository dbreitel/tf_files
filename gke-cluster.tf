#creates a cluster with 2 nodes based on custom vm, opens network for cluster and a specific ip for the kube-api
# Configure the Google Cloud provider
provider "google" {
  project = "aqua-dbank"  # Replace with your project ID
  region  = "us-central1"
  zone    = "us-central1-a"
}

# Create a GKE cluster
resource "google_container_cluster" "primary" {
  name     = "gke001"
  location = "us-central1-a"
# Disable deletion protection
  deletion_protection = false
  

  # We can't create a cluster with no node pool defined, so we create
  # the smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Kubernetes master version
  min_master_version = "latest"

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # Enable internet access
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  # Master authorized networks config
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "x.x.x.x/32" # client ip
      display_name = "Allowed IP"
    }
  }
}

# Create the node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = "us-central1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "custom-2-8192"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = "production"
    }

    tags = ["gke-node"]
  }
}

# Create firewall rule for kube-api access
resource "google_compute_firewall" "kube_api_access" {
  name    = "allow-kube-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]  # Kubernetes API server port
  }

  source_ranges = ["x.x.x.x/32"] #client ip 
  target_tags   = ["gke001"]  # This tag is automatically added to GKE master
}
