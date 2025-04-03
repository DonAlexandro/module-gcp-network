provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  vpc_name     = replace("${var.env_name} ${var.vpc_name}", " ", "-")
  cluster_name = "${var.cluster_name}-${var.env_name}"
}

## GCP VPC definition
resource "google_compute_network" "main" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
  description             = "VPC for ${local.cluster_name}"
  routing_mode            = "GLOBAL"
}

data "google_compute_zones" "available" {}

## Public Subnets
resource "google_compute_subnetwork" "public_subnet_a" {
  name          = "${local.vpc_name}-public-subnet-a"
  network       = google_compute_network.main.id
  ip_cidr_range = var.public_subnet_a_cidr
  region        = var.gcp_region
}

resource "google_compute_subnetwork" "public_subnet_b" {
  name          = "${local.vpc_name}-public-subnet-b"
  network       = google_compute_network.main.id
  ip_cidr_range = var.public_subnet_b_cidr
  region        = var.gcp_region
}

## Private Subnets
resource "google_compute_subnetwork" "private_subnet_a" {
  name                     = "${local.vpc_name}-private-subnet-a"
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.private_subnet_a_cidr
  region                   = var.gcp_region
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet_b" {
  name                     = "${local.vpc_name}-private-subnet-b"
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.private_subnet_b_cidr
  region                   = var.gcp_region
  private_ip_google_access = true
}

## Cloud NAT - Equivalent to AWS NAT Gateway
resource "google_compute_router" "router" {
  name    = "${local.vpc_name}-router"
  network = google_compute_network.main.id
  region  = var.gcp_region
}

resource "google_compute_address" "nat_ip_a" {
  name   = "${local.vpc_name}-nat-ip-a"
  region = var.gcp_region
}

resource "google_compute_address" "nat_ip_b" {
  name   = "${local.vpc_name}-nat-ip-b"
  region = var.gcp_region
}

resource "google_compute_router_nat" "nat_a" {
  name                               = "${local.vpc_name}-nat-a"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip_a.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet_a.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_router_nat" "nat_b" {
  name                               = "${local.vpc_name}-nat-b"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip_b.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet_b.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

## Route Table for Public Subnets (Like AWS IGW Route)
resource "google_compute_route" "public_route" {
  name             = "${local.vpc_name}-public-route"
  network          = google_compute_network.main.id
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_compute_route" "private_route_a" {
  name        = "${local.vpc_name}-private-route-a"
  network     = google_compute_network.main.id
  dest_range  = "0.0.0.0/0"
  priority    = 1000
  next_hop_instance = google_compute_router.router.self_link
}

resource "google_compute_route" "private_route_b" {
  name        = "${local.vpc_name}-private-route-b"
  network     = google_compute_network.main.id
  dest_range  = "0.0.0.0/0"
  priority    = 1000
  next_hop_instance = google_compute_router.router.self_link
}

## Cloud DNS (Equivalent to AWS Route 53 Private Zone)
resource "google_dns_managed_zone" "private_zone" {
  name        = "${local.vpc_name}-private-zone"
  dns_name    = "${var.env_name}.${var.vpc_name}.com."
  description = "Private DNS Zone for ${local.vpc_name}"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.self_link
    }
  }
}
