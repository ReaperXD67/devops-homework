locals {
  bootstrap = replace(templatefile("${path.module}/bootstrap.sh.tftpl", {
    source_revision = var.source_revision
    image_digest    = var.image_digest
    k3s_version     = var.k3s_version
    flux_version    = var.flux_version
    helm_version    = var.helm_version
  }), "\r\n", "\n")
}

# Separate state and resources; Session 19 keeps its original Nginx bootstrap.
module "infrastructure" {
  source             = "../../session-19-cloud/modules/infrastructure"
  project_name       = "aman-scaler-final"
  allowed_http_cidr  = var.allowed_http_cidr
  instance_type      = "c7i-flex.large"
  user_data_override = local.bootstrap
}
