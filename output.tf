output "vpc_id" {
  value = google_compute_network.main.id
}

output "subnet_ids" {
  value = [
    google_compute_subnetwork.public_subnet_a.id,
    google_compute_subnetwork.public_subnet_b.id,
    google_compute_subnetwork.private_subnet_a.id,
    google_compute_subnetwork.private_subnet_b.id
  ]
}

output "public_subnet_ids" {
  value = [
    google_compute_subnetwork.public_subnet_a.id,
    google_compute_subnetwork.public_subnet_b.id
  ]
}

output "private_subnet_ids" {
  value = [
    google_compute_subnetwork.private_subnet_a.id,
    google_compute_subnetwork.private_subnet_b.id
  ]
}

output "dns_zone_id" {
  value = google_dns_managed_zone.private_zone.id
}
