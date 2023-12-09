output "ip_master" {
  value = google_compute_address.master.instances[0].attributes.address
}
