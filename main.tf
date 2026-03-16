###############################################################################
# BigQuery Dataset
###############################################################################
resource "google_bigquery_dataset" "this" {
  project                        = var.project_id
  dataset_id                     = var.dataset_id
  friendly_name                  = var.friendly_name
  description                    = var.description
  location                       = var.location
  default_table_expiration_ms    = var.default_table_expiration_ms
  default_partition_expiration_ms = var.default_partition_expiration_ms
  delete_contents_on_destroy     = var.delete_contents_on_destroy
  max_time_travel_hours          = var.max_time_travel_hours
  labels                         = var.labels

  dynamic "default_encryption_configuration" {
    for_each = var.default_encryption_configuration != null ? [var.default_encryption_configuration] : []
    content {
      kms_key_name = default_encryption_configuration.value
    }
  }

  dynamic "access" {
    for_each = var.access
    content {
      role           = access.value.role
      user_by_email  = access.value.user_by_email
      group_by_email = access.value.group_by_email
      special_group  = access.value.special_group
      domain         = access.value.domain
    }
  }

  dynamic "access" {
    for_each = var.authorized_views
    content {
      view {
        project_id = access.value.project_id
        dataset_id = access.value.dataset_id
        table_id   = access.value.table_id
      }
    }
  }
}

###############################################################################
# Native Tables
###############################################################################
resource "google_bigquery_table" "tables" {
  for_each = var.tables

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.this.dataset_id
  table_id            = each.key
  friendly_name       = each.value.friendly_name
  description         = each.value.description
  schema              = each.value.schema
  clustering          = length(each.value.clustering) > 0 ? each.value.clustering : null
  expiration_time     = each.value.expiration_time
  labels              = merge(var.labels, each.value.labels)
  deletion_protection = each.value.deletion_protection

  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [each.value.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      field                    = time_partitioning.value.field
      expiration_ms            = time_partitioning.value.expiration_ms
      require_partition_filter = time_partitioning.value.require_partition_filter
    }
  }

  dynamic "range_partitioning" {
    for_each = each.value.range_partitioning != null ? [each.value.range_partitioning] : []
    content {
      field = range_partitioning.value.field
      range {
        start    = range_partitioning.value.range.start
        end      = range_partitioning.value.range.end
        interval = range_partitioning.value.range.interval
      }
    }
  }

  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration != null ? [each.value.encryption_configuration] : []
    content {
      kms_key_name = encryption_configuration.value.kms_key_name
    }
  }
}

###############################################################################
# Views
###############################################################################
resource "google_bigquery_table" "views" {
  for_each = var.views

  project       = var.project_id
  dataset_id    = google_bigquery_dataset.this.dataset_id
  table_id      = each.key
  friendly_name = each.value.friendly_name
  description   = each.value.description
  labels        = merge(var.labels, each.value.labels)

  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = each.value.use_legacy_sql
  }
}

###############################################################################
# Materialized Views
###############################################################################
resource "google_bigquery_table" "materialized_views" {
  for_each = var.materialized_views

  project       = var.project_id
  dataset_id    = google_bigquery_dataset.this.dataset_id
  table_id      = each.key
  friendly_name = each.value.friendly_name
  description   = each.value.description
  clustering    = length(each.value.clustering) > 0 ? each.value.clustering : null
  labels        = merge(var.labels, each.value.labels)

  deletion_protection = false

  materialized_view {
    query               = each.value.query
    enable_refresh      = each.value.enable_refresh
    refresh_interval_ms = each.value.refresh_interval_ms
  }
}

###############################################################################
# External Tables
###############################################################################
resource "google_bigquery_table" "external_tables" {
  for_each = var.external_tables

  project       = var.project_id
  dataset_id    = google_bigquery_dataset.this.dataset_id
  table_id      = each.key
  friendly_name = each.value.friendly_name
  description   = each.value.description
  schema        = each.value.schema
  labels        = merge(var.labels, each.value.labels)

  deletion_protection = false

  external_data_configuration {
    source_format = each.value.source_format
    source_uris   = each.value.source_uris
    autodetect    = each.value.autodetect

    dynamic "csv_options" {
      for_each = each.value.csv_options != null ? [each.value.csv_options] : []
      content {
        quote                 = csv_options.value.quote
        allow_jagged_rows     = csv_options.value.allow_jagged_rows
        allow_quoted_newlines = csv_options.value.allow_quoted_newlines
        encoding              = csv_options.value.encoding
        field_delimiter       = csv_options.value.field_delimiter
        skip_leading_rows     = csv_options.value.skip_leading_rows
      }
    }

    dynamic "google_sheets_options" {
      for_each = each.value.google_sheets_options != null ? [each.value.google_sheets_options] : []
      content {
        range             = google_sheets_options.value.range
        skip_leading_rows = google_sheets_options.value.skip_leading_rows
      }
    }
  }
}

###############################################################################
# Routines (UDFs and Stored Procedures)
###############################################################################
resource "google_bigquery_routine" "routines" {
  for_each = var.routines

  project         = var.project_id
  dataset_id      = google_bigquery_dataset.this.dataset_id
  routine_id      = each.key
  routine_type    = each.value.routine_type
  language        = each.value.language
  definition_body = each.value.definition_body
  description     = each.value.description
  return_type     = each.value.return_type

  dynamic "arguments" {
    for_each = each.value.arguments
    content {
      name      = arguments.value.name
      data_type = arguments.value.data_type
      mode      = arguments.value.mode
    }
  }
}

###############################################################################
# Row-Level Security Policies
###############################################################################
resource "google_bigquery_table_iam_member" "row_access" {
  for_each = {
    for key, policy in var.row_level_security_policies :
    key => policy
    if length(policy.grantees) > 0
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  table_id   = each.value.table_id
  role       = "roles/bigquery.dataViewer"
  member     = each.value.grantees[0]
}

###############################################################################
# Data Transfer Configs
###############################################################################
resource "google_bigquery_data_transfer_config" "transfers" {
  for_each = var.data_transfer_configs

  project                = var.project_id
  display_name           = each.value.display_name
  data_source_id         = each.value.data_source_id
  schedule               = each.value.schedule
  destination_dataset_id = each.value.destination_dataset_id != null ? each.value.destination_dataset_id : google_bigquery_dataset.this.dataset_id
  location               = var.location
  params                 = each.value.params
  disabled               = each.value.disabled
  service_account_name   = each.value.service_account_name
}
