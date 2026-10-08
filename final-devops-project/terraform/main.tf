# Reuse the tested infrastructure module; this root has its own independent state.
module "infrastructure" {
  source            = "../../session-19-cloud/modules/infrastructure"
  project_name      = "aman-scaler-final"
  allowed_http_cidr = var.allowed_http_cidr
  instance_type     = "t3.small"
}
