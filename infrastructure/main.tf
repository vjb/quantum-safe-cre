terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type    = string
  default = "total-velocity-493022-f0"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-east4-a"
}

# Enable APIs
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# Generate random string for unique bucket name
resource "random_id" "bucket_prefix" {
  byte_length = 4
  keepers = {
    # Generate a new id each time we switch to a new project
    project_id = var.project_id
  }
}

# Storage bucket for proofs
resource "google_storage_bucket" "proofs_bucket" {
  name          = "chainlink-pqc-proofs-${random_id.bucket_prefix.hex}"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Cloud Function Setup
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/cloud_function"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket" "function_bucket" {
  name          = "pqc-orchestrator-source-${random_id.bucket_prefix.hex}"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "source-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

resource "google_service_account" "function_sa" {
  account_id   = "pqc-orchestrator-sa"
  display_name = "PQC Orchestrator SA"
}

resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_cloudfunctions2_function" "orchestrator" {
  name        = "pqc-orchestrator"
  location    = var.region
  description = "Spins up ephemeral GCP Spot Nodes"

  build_config {
    runtime     = "python311"
    entry_point = "orchestrate"

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "512M"
    timeout_seconds    = 60

    environment_variables = {
      PROJECT_ID    = var.project_id
      ZONE          = var.zone
      TARGET_BUCKET = google_storage_bucket.proofs_bucket.name
    }
    
    service_account_email = google_service_account.function_sa.email
  }

  depends_on = [
    google_project_iam_member.compute_admin,
    google_project_iam_member.sa_user
  ]
}


output "function_uri" {
  value = google_cloudfunctions2_function.orchestrator.service_config[0].uri
}
output "proofs_bucket" {
  value = google_storage_bucket.proofs_bucket.name
}
