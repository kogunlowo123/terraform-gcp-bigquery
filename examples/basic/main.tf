provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "us-central1"
}

module "bigquery" {
  source = "../../"

  project_id  = var.project_id
  dataset_id  = "analytics_basic"
  location    = "US"
  description = "Basic analytics dataset"

  labels = {
    environment = "dev"
    team        = "data"
  }

  tables = {
    events = {
      friendly_name = "Events"
      description   = "Application events table"
      schema = jsonencode([
        {
          name = "event_id"
          type = "STRING"
          mode = "REQUIRED"
        },
        {
          name = "event_type"
          type = "STRING"
          mode = "REQUIRED"
        },
        {
          name = "event_timestamp"
          type = "TIMESTAMP"
          mode = "REQUIRED"
        },
        {
          name = "user_id"
          type = "STRING"
          mode = "NULLABLE"
        },
        {
          name = "payload"
          type = "JSON"
          mode = "NULLABLE"
        }
      ])
      deletion_protection = false
    }
  }
}

output "dataset_id" {
  description = "The dataset ID."
  value       = module.bigquery.dataset_id
}

output "table_ids" {
  description = "The table self links."
  value       = module.bigquery.table_ids
}
