output "instance_id" {
  description = "Cloud host for a later Kubernetes bootstrap via SSM."
  value       = module.infrastructure.instance_id
}
output "website_url" {
  description = "Bootstrap HTTP test page; this is not yet the final application."
  value       = module.infrastructure.website_url
}
output "bucket_name" {
  description = "Private artifact bucket."
  value       = module.infrastructure.bucket_name
}
output "vpc_id" {
  description = "Dedicated VPC for the final project."
  value       = module.infrastructure.vpc_id
}
