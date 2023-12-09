
resource "google_compute_network" "cka" {
  name                    = "cka"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "cka" {
  name          = "cka"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.cka.id
}

resource "google_compute_firewall" "ssh" {
  name = "ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.cka.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "kubeapi" {
  name = "kubeapi"
  allow {
    ports    = ["6443"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.cka.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kubeapi"]
}

resource "google_compute_firewall" "kubelet" {
  name = "kubelet"
  allow {
    ports    = ["10250"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.cka.id
  priority      = 1000
  source_tags   = ["kubelet"]
  target_tags   = ["kubelet"]
}

resource "google_compute_firewall" "etcd" {
  name = "etcd"
  allow {
    ports    = ["2379","2380"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.cka.id
  priority      = 1000
  source_tags   = ["etcd"]
  target_tags   = ["etcd"]
}

resource "google_compute_firewall" "nodeports" {
  name = "nodeports"
  allow {
    ports    = ["30000-32767"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.cka.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nodeports"]
}

resource "google_compute_address" "master" {
  name   = "master"
  region = "us-central1"
}

resource "google_compute_address" "node1" {
  name   = "node1"
  region = "us-central1"
}

resource "google_compute_instance" "master" {
  name         = "master"
  tags         = ["etcd","ssh","kubeapi","kubelet"]
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
    access_config {
      nat_ip = google_compute_address.master.address
    }
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

resource "google_compute_instance" "node1" {
  name         = "node1"
  tags         = ["ssh","kubelet","nodeports"]
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
    access_config {
      nat_ip = google_compute_address.node1.address
    }
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
