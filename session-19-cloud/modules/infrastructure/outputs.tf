output "vpc_id" {
  description = "Dedicated lab VPC ID."
  value       = aws_vpc.lab.id
}

output "subnet_id" {
  description = "Public subnet ID."
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "EC2 instance ID for Systems Manager access."
  value       = aws_instance.web.id
}

output "website_url" {
  description = "HTTP demo; reachable only from allowed_http_cidr after bootstrap finishes."
  value       = "http://${aws_instance.web.public_ip}"
}

output "bucket_name" {
  description = "Private versioned artifact bucket."
  value       = aws_s3_bucket.artifacts.id
}
