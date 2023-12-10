variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "flavor" {
  default = "e2-medium"
}

variable "image" {
  default = "debian-cloud/debian-11"
}

variable "create_nodes" {
  type    = bool
  default = false
}
