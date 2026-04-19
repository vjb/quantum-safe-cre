terraform { required_providers { google = { source = "hashicorp/google" } } }
provider "google" { project = var.project_id; region = var.region }

variable "project_id" {
  type    = string
  default = "total-velocity-493022-f0"
}

variable "region" {
  type    = string
  default = "us-central1"
}

# Storage and Registries
resource "google_artifact_registry_repository" "sp1_repo" {
  location = var.region; repository_id = "sp1-prover-repo"; format = "DOCKER"
}
resource "google_storage_bucket" "proof_bucket" {
  name = "${var.project_id}-pqc-proofs"; location = var.region; uniform_bucket_level_access = true; force_destroy = true
}

# IAM Separation of Duties
resource "google_service_account" "sa_batch_runner" {
  account_id = "sa-batch-runner"; display_name = "SP1 Batch Execution Identity"
}
resource "google_service_account" "sa_chainlink_cre" {
  account_id = "sa-chainlink-cre"; display_name = "Chainlink CRE Job Submitter"
}

# Permissions
resource "google_storage_bucket_iam_member" "runner_bucket_write" {
  bucket = google_storage_bucket.proof_bucket.name; role = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.sa_batch_runner.email}"
}
resource "google_project_iam_member" "cre_batch_editor" {
  project = var.project_id; role = "roles/batch.jobsEditor"
  member = "serviceAccount:${google_service_account.sa_chainlink_cre.email}"
}
resource "google_service_account_iam_member" "cre_act_as_runner" {
  service_account_id = google_service_account.sa_batch_runner.name; role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_chainlink_cre.email}"
}
