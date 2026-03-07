provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
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

variable "kms_key_name" {
  description = "Cloud KMS key for dataset encryption."
  type        = string
  default     = null
}

module "bigquery" {
  source = "../../"

  project_id    = var.project_id
  dataset_id    = "analytics_complete"
  location      = "US"
  friendly_name = "Complete Analytics Platform"
  description   = "Comprehensive analytics dataset with all resource types"

  default_table_expiration_ms        = 15552000000 # 180 days
  default_partition_expiration_ms    = 31104000000 # 360 days
  max_time_travel_hours              = 168
  delete_contents_on_destroy         = false
  default_encryption_configuration   = var.kms_key_name

  access = [
    {
      role          = "OWNER"
      user_by_email = "data-admin@example.com"
    },
    {
      role           = "WRITER"
      group_by_email = "data-engineers@example.com"
    },
    {
      role           = "READER"
      group_by_email = "analysts@example.com"
    },
    {
      role          = "READER"
      special_group = "projectReaders"
    }
  ]

  authorized_views = [
    {
      project_id = var.project_id
      dataset_id = "reporting"
      table_id   = "executive_dashboard"
    }
  ]

  labels = {
    environment = "production"
    team        = "data-platform"
    cost-center = "analytics"
    compliance  = "gdpr"
  }

  tables = {
    raw_events = {
      friendly_name = "Raw Events"
      description   = "Raw event ingestion table with daily partitioning"
      schema = jsonencode([
        { name = "event_id", type = "STRING", mode = "REQUIRED" },
        { name = "event_type", type = "STRING", mode = "REQUIRED" },
        { name = "event_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "user_id", type = "STRING", mode = "NULLABLE" },
        { name = "session_id", type = "STRING", mode = "NULLABLE" },
        { name = "device_type", type = "STRING", mode = "NULLABLE" },
        { name = "country", type = "STRING", mode = "NULLABLE" },
        { name = "payload", type = "JSON", mode = "NULLABLE" }
      ])
      time_partitioning = {
        type                     = "DAY"
        field                    = "event_timestamp"
        expiration_ms            = 7776000000 # 90 days
        require_partition_filter = true
      }
      clustering          = ["event_type", "country", "user_id"]
      deletion_protection = true
      labels = {
        data-classification = "confidential"
      }
    }

    user_dimensions = {
      friendly_name = "User Dimensions"
      description   = "User dimension table for analytics joins"
      schema = jsonencode([
        { name = "user_id", type = "STRING", mode = "REQUIRED" },
        { name = "email_hash", type = "STRING", mode = "NULLABLE" },
        { name = "display_name", type = "STRING", mode = "NULLABLE" },
        { name = "signup_date", type = "DATE", mode = "REQUIRED" },
        { name = "country", type = "STRING", mode = "NULLABLE" },
        { name = "subscription_tier", type = "STRING", mode = "NULLABLE" },
        { name = "lifetime_value", type = "FLOAT64", mode = "NULLABLE" },
        { name = "is_active", type = "BOOL", mode = "REQUIRED" }
      ])
      deletion_protection = true
    }

    metrics_hourly = {
      friendly_name = "Hourly Metrics"
      description   = "Pre-aggregated hourly metrics"
      schema = jsonencode([
        { name = "metric_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "metric_name", type = "STRING", mode = "REQUIRED" },
        { name = "dimension_1", type = "STRING", mode = "NULLABLE" },
        { name = "dimension_2", type = "STRING", mode = "NULLABLE" },
        { name = "value_sum", type = "FLOAT64", mode = "REQUIRED" },
        { name = "value_count", type = "INT64", mode = "REQUIRED" },
        { name = "value_min", type = "FLOAT64", mode = "NULLABLE" },
        { name = "value_max", type = "FLOAT64", mode = "NULLABLE" }
      ])
      time_partitioning = {
        type  = "HOUR"
        field = "metric_timestamp"
      }
      clustering          = ["metric_name", "dimension_1"]
      deletion_protection = false
    }
  }

  views = {
    active_users_summary = {
      friendly_name = "Active Users Summary"
      description   = "Summary of active users by tier and country"
      query         = <<-SQL
        SELECT
          country,
          subscription_tier,
          COUNT(*) AS user_count,
          AVG(lifetime_value) AS avg_ltv
        FROM `${var.project_id}.analytics_complete.user_dimensions`
        WHERE is_active = TRUE
        GROUP BY country, subscription_tier
      SQL
    }

    recent_events = {
      friendly_name = "Recent Events"
      description   = "Events from the last 7 days"
      query         = <<-SQL
        SELECT *
        FROM `${var.project_id}.analytics_complete.raw_events`
        WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
      SQL
    }
  }

  materialized_views = {
    daily_event_counts = {
      friendly_name       = "Daily Event Counts"
      description         = "Materialized daily event counts by type"
      enable_refresh      = true
      refresh_interval_ms = 3600000 # 1 hour
      query               = <<-SQL
        SELECT
          DATE(event_timestamp) AS event_date,
          event_type,
          country,
          COUNT(*) AS event_count,
          COUNT(DISTINCT user_id) AS unique_users
        FROM `${var.project_id}.analytics_complete.raw_events`
        GROUP BY event_date, event_type, country
      SQL
      clustering = ["event_type"]
    }
  }

  external_tables = {
    gcs_import_data = {
      friendly_name = "GCS Import Data"
      description   = "External table reading CSV files from GCS"
      source_format = "CSV"
      source_uris   = ["gs://${var.project_id}-data-import/*.csv"]
      autodetect    = false
      schema = jsonencode([
        { name = "id", type = "STRING", mode = "REQUIRED" },
        { name = "name", type = "STRING", mode = "NULLABLE" },
        { name = "value", type = "FLOAT64", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" }
      ])
      csv_options = {
        skip_leading_rows    = 1
        field_delimiter      = ","
        allow_quoted_newlines = true
      }
    }
  }

  routines = {
    calculate_retention = {
      routine_type    = "SCALAR_FUNCTION"
      language        = "SQL"
      description     = "Calculates user retention rate for a given period"
      definition_body = <<-SQL
        (
          SELECT SAFE_DIVIDE(
            COUNT(DISTINCT CASE WHEN event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL period_days DAY) THEN user_id END),
            COUNT(DISTINCT user_id)
          )
          FROM `${var.project_id}.analytics_complete.raw_events`
          WHERE event_type = event_filter
        )
      SQL
      return_type = "{\"typeKind\": \"FLOAT64\"}"
      arguments = [
        {
          name      = "event_filter"
          data_type = "{\"typeKind\": \"STRING\"}"
        },
        {
          name      = "period_days"
          data_type = "{\"typeKind\": \"INT64\"}"
        }
      ]
    }

    cleanup_old_data = {
      routine_type    = "PROCEDURE"
      language        = "SQL"
      description     = "Procedure to clean up data older than specified days"
      definition_body = <<-SQL
        BEGIN
          DELETE FROM `${var.project_id}.analytics_complete.raw_events`
          WHERE event_timestamp < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL retention_days DAY);
        END
      SQL
      arguments = [
        {
          name      = "retention_days"
          data_type = "{\"typeKind\": \"INT64\"}"
          mode      = "IN"
        }
      ]
    }
  }

  data_transfer_configs = {
    daily_aggregation = {
      display_name         = "Daily Aggregation Query"
      data_source_id       = "scheduled_query"
      schedule             = "every 24 hours"
      destination_dataset_id = "analytics_complete"
      params = {
        query = "SELECT DATE(event_timestamp) as dt, event_type, COUNT(*) as cnt FROM `${var.project_id}.analytics_complete.raw_events` WHERE event_timestamp >= @run_time GROUP BY 1, 2"
        destination_table_name_template = "daily_aggregation_{run_date}"
        write_disposition               = "WRITE_TRUNCATE"
      }
    }
  }
}

output "dataset_id" {
  description = "The dataset ID."
  value       = module.bigquery.dataset_id
}

output "dataset_self_link" {
  description = "Dataset self link."
  value       = module.bigquery.dataset_self_link
}

output "table_ids" {
  description = "Table self links."
  value       = module.bigquery.table_ids
}

output "view_ids" {
  description = "View self links."
  value       = module.bigquery.view_ids
}

output "materialized_view_ids" {
  description = "Materialized view self links."
  value       = module.bigquery.materialized_view_ids
}

output "routine_ids" {
  description = "Routine IDs."
  value       = module.bigquery.routine_ids
}

output "transfer_config_names" {
  description = "Transfer config names."
  value       = module.bigquery.transfer_config_names
}
