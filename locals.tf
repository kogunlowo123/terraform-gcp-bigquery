locals {
  default_labels = {
    managed-by = "terraform"
  }

  merged_labels = merge(local.default_labels, var.labels)

  dataset_fqn = "${var.project_id}:${var.dataset_id}"

  # Flatten access entries for iteration
  access_entries = [
    for entry in var.access : {
      role           = entry.role
      user_by_email  = entry.user_by_email
      group_by_email = entry.group_by_email
      special_group  = entry.special_group
      domain         = entry.domain
    }
  ]

  # Build authorized view access entries
  authorized_view_entries = [
    for view in var.authorized_views : {
      project_id = view.project_id
      dataset_id = view.dataset_id
      table_id   = view.table_id
    }
  ]

  # Merge table labels with default labels
  table_labels = {
    for k, v in var.tables : k => merge(local.default_labels, v.labels)
  }

  view_labels = {
    for k, v in var.views : k => merge(local.default_labels, v.labels)
  }

  materialized_view_labels = {
    for k, v in var.materialized_views : k => merge(local.default_labels, v.labels)
  }
}
