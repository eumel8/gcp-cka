output "ip_master" {
  value = google_compute_address.master.address
}
output "ip_node1" {
  value = google_compute_address.node1.address
}
