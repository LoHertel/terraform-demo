locals {
  # hard coded for each environment
  environment = "stage"

  project     = var.project
  region      = var.region
  zone        = "${var.region}-${var.zone_suffix}"
  name_prefix = "${local.project}-${local.region}"
  buckets = [
    "${local.name_prefix}-data-lake",
    "${local.name_prefix}-data-lake-anonymized"
  ]
}


variable "project" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region for GCP resources. All available regions could be found here: https://cloud.google.com/storage/docs/locations#location-r"
  default     = "us-east1"
  type        = string
}

variable "zone_suffix" {
  description = "Zone Suffix for Region. All available zones for a region could be found here: https://cloud.google.com/compute/docs/regions-zones#available"
  default     = "d"
  type        = string
}
