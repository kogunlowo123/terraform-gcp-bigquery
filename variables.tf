variable "project_id" {
  description = "The GCP project ID where BigQuery resources will be created."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "location" {
  description = "The geographic location for the dataset."
  type        = string
  default     = "US"
}

variable "dataset_id" {
  description = "A unique ID for the dataset, must be alphanumeric (plus underscores)."
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
  description = "Default lifetime in milliseconds for tables (minimum 3600000)."
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
  description = "Time travel window in hours, value can be from 48 to 168 (2 to 7 days)."
  type        = number
  default     = 168

  validation {
    condition     = var.max_time_travel_hours >= 48 && var.max_time_travel_hours <= 168
    error_message = "Max time travel hours must be between 48 and 168."
  }
}

variable "labels" {
  description = "Key-value labels to apply to the dataset and its resources."
  type        = map(string)
  default     = {}
}

variable "default_encryption_configuration" {
  description = "Cloud KMS key name for default table encryption."
  type        = string
  default     = null
}

variable "access" {
  description = "Access control list for the dataset with role, user_by_email, group_by_email, special_group, and domain."
  type = list(object({
    role           = string
    user_by_email  = optional(string)
    group_by_email = optional(string)
    special_group  = optional(string)
    domain         = optional(string)
  }))
  default = []
}

variable "authorized_views" {
  description = "List of authorized views that can access the dataset."
  type = list(object({
    project_id = string
    dataset_id = string
    table_id   = string
  }))
  default = []
}

variable "tables" {
  description = "Map of native BigQuery tables to create, keyed by table_id."
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
  description = "Map of BigQuery views to create, keyed by table_id."
  type = map(object({
    friendly_name  = optional(string, "")
    description    = optional(string, "")
    query          = string
    use_legacy_sql = optional(bool, false)
    labels         = optional(map(string), {})
  }))
  default = {}
}

variable "materialized_views" {
  description = "Map of materialized views to create, keyed by table_id."
  type = map(object({
    friendly_name       = optional(string, "")
    description         = optional(string, "")
    query               = string
    enable_refresh      = optional(bool, true)
    refresh_interval_ms = optional(number, 1800000)
    clustering          = optional(list(string), [])
    labels              = optional(map(string), {})
  }))
  default = {}
}

variable "external_tables" {
  description = "Map of external tables to create, keyed by table_id."
  type = map(object({
    friendly_name = optional(string, "")
    description   = optional(string, "")
    schema        = optional(string)
    source_format = string
    source_uris   = list(string)
    autodetect    = optional(bool, true)
    labels        = optional(map(string), {})
    csv_options = optional(object({
      quote                  = optional(string, "\"")
      allow_jagged_rows      = optional(bool, false)
      allow_quoted_newlines   = optional(bool, false)
      encoding               = optional(string, "UTF-8")
      field_delimiter        = optional(string, ",")
      skip_leading_rows      = optional(number, 0)
    }))
    google_sheets_options = optional(object({
      range             = optional(string)
      skip_leading_rows = optional(number, 0)
    }))
  }))
  default = {}
}

variable "routines" {
  description = "Map of BigQuery routines (UDFs or stored procedures) to create, keyed by routine_id."
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
  description = "Map of row-level security policies keyed by a unique identifier."
  type = map(object({
    table_id         = string
    filter_predicate = string
    grantees         = list(string)
  }))
  default = {}
}

variable "data_transfer_configs" {
  description = "Map of BigQuery Data Transfer Service configurations keyed by a unique identifier."
  type = map(object({
    display_name           = string
    data_source_id         = string
    schedule               = optional(string)
    destination_dataset_id = optional(string)
    params                 = map(string)
    disabled               = optional(bool, false)
    service_account_name   = optional(string)
  }))
  default = {}
}
