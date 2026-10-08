output "vpc_id" {
  description = "Dedicated lab VPC."
  value       = module.infrastructure.vpc_id
}
output "subnet_id" {
  description = "Public subnet."
  value       = module.infrastructure.subnet_id
}
output "instance_id" {
  description = "EC2 ID for SSM sessions."
  value       = module.infrastructure.instance_id
}
output "website_url" {
  description = "HTTP demo address, restricted by the security group."
  value       = module.infrastructure.website_url
}
output "bucket_name" {
  description = "Private artifact bucket."
  value       = module.infrastructure.bucket_name
}
