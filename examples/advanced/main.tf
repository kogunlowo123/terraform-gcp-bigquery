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

  project_id    = var.project_id
  dataset_id    = "analytics_advanced"
  location      = "US"
  friendly_name = "Advanced Analytics"
  description   = "Analytics dataset with partitioned tables, views, and access controls"

  default_table_expiration_ms     = 7776000000 # 90 days
  default_partition_expiration_ms = 15552000000 # 180 days
  max_time_travel_hours           = 168

  access = [
    {
      role          = "OWNER"
      user_by_email = "admin@example.com"
    },
    {
      role           = "READER"
      group_by_email = "analysts@example.com"
    },
    {
      role          = "WRITER"
      special_group = "projectWriters"
    }
  ]

  labels = {
    environment = "staging"
    team        = "data-engineering"
    cost-center = "analytics"
  }

  tables = {
    page_views = {
      friendly_name = "Page Views"
      description   = "Website page view events"
      schema = jsonencode([
        { name = "view_id", type = "STRING", mode = "REQUIRED" },
        { name = "page_url", type = "STRING", mode = "REQUIRED" },
        { name = "user_id", type = "STRING", mode = "NULLABLE" },
        { name = "session_id", type = "STRING", mode = "REQUIRED" },
        { name = "view_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "referrer", type = "STRING", mode = "NULLABLE" },
        { name = "user_agent", type = "STRING", mode = "NULLABLE" },
        { name = "country", type = "STRING", mode = "NULLABLE" }
      ])
      time_partitioning = {
        type                     = "DAY"
        field                    = "view_timestamp"
        require_partition_filter = true
      }
      clustering          = ["country", "user_id"]
      deletion_protection = false
    }

    user_profiles = {
      friendly_name = "User Profiles"
      description   = "User profile dimension table"
      schema = jsonencode([
        { name = "user_id", type = "STRING", mode = "REQUIRED" },
        { name = "email", type = "STRING", mode = "NULLABLE" },
        { name = "display_name", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "country", type = "STRING", mode = "NULLABLE" },
        { name = "tier", type = "STRING", mode = "NULLABLE" }
      ])
      deletion_protection = false
    }
  }

  views = {
    daily_page_views = {
      friendly_name = "Daily Page Views"
      description   = "Aggregated daily page view counts"
      query         = <<-SQL
        SELECT
          DATE(view_timestamp) AS view_date,
          country,
          COUNT(*) AS view_count,
          COUNT(DISTINCT user_id) AS unique_users
        FROM `${var.project_id}.analytics_advanced.page_views`
        GROUP BY view_date, country
      SQL
    }
  }

  routines = {
    get_user_views = {
      routine_type    = "SCALAR_FUNCTION"
      language        = "SQL"
      definition_body = "(SELECT COUNT(*) FROM `${var.project_id}.analytics_advanced.page_views` WHERE user_id = uid)"
      description     = "Returns total page views for a user"
      return_type     = "{\"typeKind\": \"INT64\"}"
      arguments = [
        {
          name      = "uid"
          data_type = "{\"typeKind\": \"STRING\"}"
        }
      ]
    }
  }
}

output "dataset_id" {
  description = "The dataset ID."
  value       = module.bigquery.dataset_id
}

output "table_ids" {
  description = "Table self links."
  value       = module.bigquery.table_ids
}

output "view_ids" {
  description = "View self links."
  value       = module.bigquery.view_ids
}
