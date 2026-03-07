variable "project_id" {
  description = "The GCP project ID where BigQuery resources will be created."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "location" {
  description = "The geographic location for the dataset. See https://cloud.google.com/bigquery/docs/locations."
  type        = string
  default     = "US"
}

variable "dataset_id" {
  description = "A unique ID for the dataset. Must be alphanumeric (plus underscores)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]{0,1023}$", var.dataset_id))
    error_message = "Dataset ID must start with a letter or underscore, contain only letters, numbers, and underscores, and be at most 1024 characters."
  }
}

variable "friendly_name" {
  description = "A descriptive name for the dataset."
  type        = string
  default     = ""
}

variable "description" {
  description = "A user-friendly description of the dataset."
  type        = string
  default     = ""
}

variable "default_table_expiration_ms" {
  description = "Default lifetime (in milliseconds) for tables. Minimum value is 3600000 (one hour)."
  type        = number
  default     = null

  validation {
    condition     = var.default_table_expiration_ms == null || var.default_table_expiration_ms >= 3600000
    error_message = "Default table expiration must be at least 3600000 ms (1 hour)."
  }
}

variable "default_partition_expiration_ms" {
  description = "Default partition expiration in milliseconds for partitioned tables."
  type        = number
  default     = null
}

variable "delete_contents_on_destroy" {
  description = "If true, delete all tables in the dataset when destroying the resource."
  type        = bool
  default     = false
}

variable "max_time_travel_hours" {
  description = "Defines the time travel window in hours. Value can be from 48 to 168 hours (2 to 7 days)."
  type        = number
  default     = 168

  validation {
    condition     = var.max_time_travel_hours >= 48 && var.max_time_travel_hours <= 168
    error_message = "Max time travel hours must be between 48 and 168."
  }
}

variable "labels" {
  description = "Key-value labels to apply to the dataset."
  type        = map(string)
  default     = {}
}

variable "default_encryption_configuration" {
  description = "Cloud KMS key name for default table encryption."
  type        = string
  default     = null
}

variable "access" {
  description = <<-EOT
    Access control list for the dataset. Each entry contains:
    - role: READER, WRITER, or OWNER
    - user_by_email: (Optional) Email of the user
    - group_by_email: (Optional) Email of the group
    - special_group: (Optional) Special group (projectReaders, projectWriters, projectOwners, allAuthenticatedUsers)
    - domain: (Optional) Domain to grant access
  EOT
  type = list(object({
    role            = string
    user_by_email   = optional(string)
    group_by_email  = optional(string)
    special_group   = optional(string)
    domain          = optional(string)
  }))
  default = []
}

variable "authorized_views" {
  description = <<-EOT
    List of authorized views that can access the dataset. Each entry contains:
    - project_id: Project of the authorized view
    - dataset_id: Dataset of the authorized view
    - table_id: Table ID of the authorized view
  EOT
  type = list(object({
    project_id = string
    dataset_id = string
    table_id   = string
  }))
  default = []
}

variable "tables" {
  description = <<-EOT
    Map of native BigQuery tables to create. Key is the table_id. Each table object contains:
    - friendly_name: Display name
    - description: Table description
    - schema: JSON schema definition (string)
    - time_partitioning: (Optional) Partitioning config with type (DAY, HOUR, MONTH, YEAR), field, expiration_ms, require_partition_filter
    - range_partitioning: (Optional) Range partitioning config with field, range (start, end, interval)
    - clustering: (Optional) List of clustering column names (up to 4)
    - expiration_time: (Optional) Expiration time in epoch milliseconds
    - labels: (Optional) Labels for the table
    - deletion_protection: (Optional) Prevent table deletion
  EOT
  type = map(object({
    friendly_name = optional(string, "")
    description   = optional(string, "")
    schema        = string
    time_partitioning = optional(object({
      type                     = string
      field                    = optional(string)
      expiration_ms            = optional(number)
      require_partition_filter = optional(bool, false)
    }))
    range_partitioning = optional(object({
      field = string
      range = object({
        start    = number
        end      = number
        interval = number
      })
    }))
    clustering          = optional(list(string), [])
    expiration_time     = optional(number)
    labels              = optional(map(string), {})
    deletion_protection = optional(bool, true)
    encryption_configuration = optional(object({
      kms_key_name = string
    }))
  }))
  default = {}
}

variable "views" {
  description = <<-EOT
    Map of BigQuery views to create. Key is the table_id. Each view contains:
    - friendly_name: Display name
    - description: View description
    - query: SQL query defining the view
    - use_legacy_sql: Whether to use legacy SQL (default: false)
    - labels: Labels for the view
  EOT
  type = map(object({
    friendly_name = optional(string, "")
    description   = optional(string, "")
    query         = string
    use_legacy_sql = optional(bool, false)
    labels        = optional(map(string), {})
  }))
  default = {}
}

variable "materialized_views" {
  description = <<-EOT
    Map of materialized views to create. Key is the table_id. Each contains:
    - friendly_name: Display name
    - description: Description
    - query: SQL query for the materialized view
    - enable_refresh: Whether to enable automatic refresh
    - refresh_interval_ms: Refresh interval in milliseconds (minimum 60000)
    - clustering: List of clustering columns
    - labels: Labels
  EOT
  type = map(object({
    friendly_name      = optional(string, "")
    description        = optional(string, "")
    query              = string
    enable_refresh     = optional(bool, true)
    refresh_interval_ms = optional(number, 1800000)
    clustering         = optional(list(string), [])
    labels             = optional(map(string), {})
  }))
  default = {}
}

variable "external_tables" {
  description = <<-EOT
    Map of external tables to create. Key is the table_id. Each contains:
    - friendly_name: Display name
    - description: Description
    - schema: JSON schema string
    - source_format: CSV, NEWLINE_DELIMITED_JSON, AVRO, PARQUET, ORC, GOOGLE_SHEETS
    - source_uris: List of URIs for the external data
    - autodetect: Whether to auto-detect schema
    - labels: Labels
    - csv_options: (Optional) CSV-specific options
    - google_sheets_options: (Optional) Google Sheets-specific options
  EOT
  type = map(object({
    friendly_name = optional(string, "")
    description   = optional(string, "")
    schema        = optional(string)
    source_format = string
    source_uris   = list(string)
    autodetect    = optional(bool, true)
    labels        = optional(map(string), {})
    csv_options = optional(object({
      quote                 = optional(string, "\"")
      allow_jagged_rows     = optional(bool, false)
      allow_quoted_newlines  = optional(bool, false)
      encoding              = optional(string, "UTF-8")
      field_delimiter       = optional(string, ",")
      skip_leading_rows     = optional(number, 0)
    }))
    google_sheets_options = optional(object({
      range             = optional(string)
      skip_leading_rows = optional(number, 0)
    }))
  }))
  default = {}
}

variable "routines" {
  description = <<-EOT
    Map of BigQuery routines (UDFs or stored procedures) to create. Key is the routine_id. Each contains:
    - routine_type: SCALAR_FUNCTION, TABLE_VALUED_FUNCTION, or PROCEDURE
    - language: SQL or JAVASCRIPT
    - definition_body: The SQL or JavaScript function body
    - description: Description
    - return_type: Return type (JSON string) for functions
    - arguments: List of argument objects with name, data_type, mode (IN, OUT, INOUT)
  EOT
  type = map(object({
    routine_type    = string
    language        = optional(string, "SQL")
    definition_body = string
    description     = optional(string, "")
    return_type     = optional(string)
    arguments = optional(list(object({
      name      = string
      data_type = string
      mode      = optional(string, "IN")
    })), [])
  }))
  default = {}
}

variable "row_level_security_policies" {
  description = <<-EOT
    Map of row-level security policies. Key is a unique identifier. Each contains:
    - table_id: The table to apply the policy to
    - filter_predicate: SQL expression for row filtering
    - grantees: List of members (user:, group:, serviceAccount:, domain:)
  EOT
  type = map(object({
    table_id         = string
    filter_predicate = string
    grantees         = list(string)
  }))
  default = {}
}

variable "data_transfer_configs" {
  description = <<-EOT
    Map of BigQuery Data Transfer Service configurations. Key is a unique identifier. Each contains:
    - display_name: Display name
    - data_source_id: Data source (e.g., scheduled_query, google_cloud_storage, etc.)
    - schedule: Transfer schedule (cron-like format)
    - destination_dataset_id: Target dataset ID
    - params: Map of parameters specific to the data source
    - disabled: Whether the transfer is disabled
    - service_account_name: Service account email
  EOT
  type = map(object({
    display_name         = string
    data_source_id       = string
    schedule             = optional(string)
    destination_dataset_id = optional(string)
    params               = map(string)
    disabled             = optional(bool, false)
    service_account_name = optional(string)
  }))
  default = {}
}
