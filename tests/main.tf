module "test" {
  source = "../"

  project_id    = "test-project-id"
  location      = "US"
  dataset_id    = "test_analytics_dataset"
  friendly_name = "Test Analytics Dataset"
  description   = "Test BigQuery dataset for analytics workloads"

  default_table_expiration_ms     = 7776000000
  default_partition_expiration_ms = 5184000000
  delete_contents_on_destroy      = true
  max_time_travel_hours           = 168

  labels = {
    environment = "test"
    managed_by  = "terraform"
  }

  tables = {
    events = {
      friendly_name = "Events Table"
      description   = "Raw events data"
      schema = jsonencode([
        { name = "event_id", type = "STRING", mode = "REQUIRED" },
        { name = "event_type", type = "STRING", mode = "REQUIRED" },
        { name = "event_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "user_id", type = "STRING", mode = "NULLABLE" },
        { name = "payload", type = "JSON", mode = "NULLABLE" }
      ])
      time_partitioning = {
        type  = "DAY"
        field = "event_timestamp"
      }
      clustering          = ["event_type", "user_id"]
      deletion_protection = false
    }
  }

  views = {
    daily_event_summary = {
      friendly_name = "Daily Event Summary"
      description   = "Aggregated daily event counts"
      query         = "SELECT DATE(event_timestamp) as event_date, event_type, COUNT(*) as event_count FROM `test-project-id.test_analytics_dataset.events` GROUP BY 1, 2"
    }
  }

  access = [
    {
      role          = "READER"
      special_group = "projectReaders"
    }
  ]
}
