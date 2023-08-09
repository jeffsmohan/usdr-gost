namespace = "gost-prod"
env       = "production"

// Common
ssm_service_parameters_path_prefix    = "/gost/prod"
ssm_deployment_parameters_path_prefix = "/gost/prod/deploy-config"

// Website
website_enabled     = true
website_domain_name = "grants.usdigitalresponse.org"

// ECS Cluster
cluster_container_insights_enabled = true

// API / Backend
api_enabled                    = true
api_container_image_tag        = "stable"
api_default_desired_task_count = 3
api_minumum_task_count         = 2
api_maximum_task_count         = 5
api_enable_grants_scraper      = true
api_enable_grants_digest       = true
api_log_retention_in_days      = 30
api_datadog_environment_variables = {
  DD_PROFILING_ENABLED = true,
}

// Postgres
postgres_enabled                   = true
postgres_prevent_destroy           = true
postgres_snapshot_before_destroy   = true
postgres_apply_changes_immediately = false

// Grant events consumer
consume_grants_source_event_bus_name = "default"
consume_grants_datadog_environment_variables = {
  DD_PROFILING_ENABLED = true,
}
