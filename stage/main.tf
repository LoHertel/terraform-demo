terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "org-example-xxxxxx-tf-state"
    prefix = "stage"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.73.1, < 5.0"
    }
  }
}

provider "google" {
  project = local.project
  region  = local.region
  zone    = local.zone
}


# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data_lake_buckets" {
  for_each                    = toset(local.buckets)
  name                        = each.key
  storage_class               = "STANDARD"
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  force_destroy               = true # Set to "false" in real-world projects! Just set to "true" to clear up this demo resource easier.

  versioning {
    enabled = false
  }
}


# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "etl_host" {
  name                      = "etl-host-${local.environment}"
  machine_type              = "e2-micro"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20220420"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link

    access_config {
      // Ephemeral public IP
      network_tier = "STANDARD"
    }
  }

  metadata = {
    enable-oslogin = true
  }

  tags = ["ssh-server"]
}

resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network-${local.environment}"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "ssh_server" {
  name    = "default-allow-ssh-${local.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere to instances with an ssh-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}