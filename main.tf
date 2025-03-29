provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  vpc_name     = "${var.env_name} ${var.vpc_name}"
  cluster_name = "${var.cluster_name}-${var.env_name}"
}

## GCP VPC definition
resource "google_compute_network" "main" {
  name                    = replace(local.vpc_name, " ", "-")
  auto_create_subnetworks = false
  description = "VPC for ${local.cluster_name}"
  routing_mode = "GLOBAL"
}

data "google_compute_zones" "available" {}

resource "google_compute_subnetwork" "public_subnet_a" {
  name          = "${local.vpc_name}-public-subnet-a"
  network       = google_compute_network.main.id
  ip_cidr_range = var.public_subnet_a_cidr
  region        = data.google_compute_zones.available.names[0]
  private_ip_google_access = false
}

resource "google_compute_subnetwork" "public_subnet_b" {
  name          = "${local.vpc_name}-public-subnet-b"
  network       = google_compute_network.main.id
  ip_cidr_range = var.public_subnet_b_cidr
  region        = data.google_compute_zones.available.names[1]

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private_subnet_a" {
  name          = "${local.vpc_name}-private-subnet-a"
  network       = google_compute_network.main.id
  ip_cidr_range = var.private_subnet_a_cidr
  region        = data.google_compute_zones.available.names[0]

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet_b" {
  name          = "${local.vpc_name}-private-subnet-b"
  network       = google_compute_network.main.id
  ip_cidr_range = var.private_subnet_b_cidr
  region        = data.google_compute_zones.available.names[1]

  private_ip_google_access = true
}

