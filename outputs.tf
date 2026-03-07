output "dataset_id" {
  description = "The dataset ID."
  value       = google_bigquery_dataset.this.dataset_id
}

output "dataset_self_link" {
  description = "The URI of the dataset."
  value       = google_bigquery_dataset.this.self_link
}

output "dataset_project" {
  description = "The project in which the dataset was created."
  value       = google_bigquery_dataset.this.project
}

output "dataset_location" {
  description = "The geographic location of the dataset."
  value       = google_bigquery_dataset.this.location
}

output "dataset_creation_time" {
  description = "The time when the dataset was created, in milliseconds since epoch."
  value       = google_bigquery_dataset.this.creation_time
}

output "dataset_last_modified_time" {
  description = "The date when the dataset was last modified, in milliseconds since epoch."
  value       = google_bigquery_dataset.this.last_modified_time
}

output "dataset_etag" {
  description = "A hash of the resource."
  value       = google_bigquery_dataset.this.etag
}

output "table_ids" {
  description = "Map of table IDs to their self links."
  value = {
    for k, v in google_bigquery_table.tables : k => v.self_link
  }
}

output "view_ids" {
  description = "Map of view IDs to their self links."
  value = {
    for k, v in google_bigquery_table.views : k => v.self_link
  }
}

output "materialized_view_ids" {
  description = "Map of materialized view IDs to their self links."
  value = {
    for k, v in google_bigquery_table.materialized_views : k => v.self_link
  }
}

output "external_table_ids" {
  description = "Map of external table IDs to their self links."
  value = {
    for k, v in google_bigquery_table.external_tables : k => v.self_link
  }
}

output "routine_ids" {
  description = "Map of routine IDs."
  value = {
    for k, v in google_bigquery_routine.routines : k => v.routine_id
  }
}

output "transfer_config_names" {
  description = "Map of data transfer config names."
  value = {
    for k, v in google_bigquery_data_transfer_config.transfers : k => v.name
  }
}

output "effective_labels" {
  description = "The effective labels on the dataset."
  value       = google_bigquery_dataset.this.effective_labels
}
