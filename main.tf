
resource "google_compute_network" "cka" {
  name                    = "cka"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "cka" {
  name          = "cka"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1-a"
  network       = google_compute_network.cka.id
}

resource "google_compute_instance" "master" {
  name         = "master"
  tags         = ["allow-ssh"]
  zone         = "us-central1-a"
  machine_type = "e2-medium"
  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }
  network_interface {
    network    = google_compute_network.cka.id
    subnetwork = google_compute_subnetwork.cka.id
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  metadata = {
    "ssh-keys" = <<EOT
      cka:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCziLvxHq94NKN7Nzvj4sNVU21QQHDwiQpafGUHl71z/KqcNYgtkqnwH7GQTlisKc4+GuM4wM1+BsTLt/orDQLu2fG4m4PqHa2GyaWJcWnEwkHYifa31MTPUIlAgdjMC2HxXYiYTCyK8hI4Uc9d20gQ0/KsbHzKYgCRBRHaqLIxZx0HM5PewKAWxmiU7TOQhYy7ETsS9A7h3LIFSGmXDDUroGan+qjGiXobn4/tDeljWC88RscFI1VNJyI25cIpclm0mfxtXQTC4iRG/h3E3uRZFuvpNsgCLxjcJU3L9lNWeWeyH54wR/xRgNsETI2JdHlznhB4iyOC5Cb2YT28TG2MO8GOuGESRC6uyDGegDhGuh4vtZSEj1QQUnmtcy3zo5aXgRloGtB3Q/cTklY3C0fRECGy+XXOo5Z15Vd6+hA23WEWn8zkCXtOsO0oZJqPKJrdXN7OSH0o3VdNbVH5s/QCPVceF4vMhmA2syO8VqMtfp8g4zTzjZ7m1XmUAi2hH4s= cka
     EOT
  }
}
