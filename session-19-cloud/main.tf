module "infrastructure" {
  source            = "./modules/infrastructure"
  project_name      = var.project_name
  allowed_http_cidr = var.allowed_http_cidr
  instance_type     = var.instance_type
}
