terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.26.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_service_account" "module3_sa" {
  account_id   = "module3-data-vm-sa"
  display_name = "Module 3 Data VM Service Account"
}

data "google_storage_bucket" "existing_bucket" {
  name = var.gcs_bucket_name
}

data "google_bigquery_dataset" "existing_dataset" {
  dataset_id = var.bq_dataset_id
}

resource "google_compute_instance" "module3_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {

    }
  }

  service_account {
    email  = google_service_account.module3_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    bucket-name = var.gcs_bucket_name
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get upgrade -y

    apt-get install -y python3 python3-pip python3-venv curl git

    mkdir -p /opt/module3
    cd /opt/module3

    python3 -m venv venv

    /opt/module3/venv/bin/pip install --upgrade pip
    /opt/module3/venv/bin/pip install google-cloud-storage google-cloud-bigquery pandas pyarrow

    git clone https://github.com/GuilhermeBustos/data-engineering-zoomcamp-homework
    cd data-engineering-zoomcamp-homework/module-3/
    /opt/module3/venv/bin/python3 main.py
EOT

  tags = ["module3", "allow-ssh"]

  labels = {
    environment = "development"
  }
}

resource "google_storage_bucket_iam_member" "vm_bucket_access" {
  bucket = data.google_storage_bucket.existing_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.module3_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "vm_bq_data_editor" {
  dataset_id = data.google_bigquery_dataset.existing_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.module3_sa.email}"
}

resource "google_project_iam_member" "vm_bq_job_user" {
  project = var.project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.module3_sa.email}"
}