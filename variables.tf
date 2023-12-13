variable "region" {
  default = "europe-west3-c"
}

variable "zone" {
  default = "europe-west3-c"
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

variable "network" {
  # default = "sbx-spoke-0"
}

variable "subnetwork" {
  # default = "sbx-ew3-shared"
}
