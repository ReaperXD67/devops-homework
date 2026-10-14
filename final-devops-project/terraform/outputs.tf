output "instance_id" {
  description = "Cloud K3s host; inspect bootstrap and workloads through SSM."
  value       = module.infrastructure.instance_id
}
output "website_url" {
  description = "Final application through Traefik once bootstrap completes; restricted to the learner IPv4 /32."
  value       = module.infrastructure.website_url
}

output "application_image" {
  description = "Immutable application image requested by the Flux HelmRelease."
  value       = "ghcr.io/reaperxd67/devops-homework@${var.image_digest}"
}

output "chart_source_revision" {
  description = "Git source revision reconciled by Flux."
  value       = var.source_revision
}
output "bucket_name" {
  description = "Private artifact bucket."
  value       = module.infrastructure.bucket_name
}
output "vpc_id" {
  description = "Dedicated VPC for the final project."
  value       = module.infrastructure.vpc_id
}
