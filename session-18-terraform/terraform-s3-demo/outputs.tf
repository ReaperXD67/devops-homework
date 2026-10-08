output "bucket_name" {
  description = "Unique name of the private demo bucket."
  value       = aws_s3_bucket.demo.id
}

output "bucket_arn" {
  description = "ARN for least-privilege IAM policies."
  value       = aws_s3_bucket.demo.arn
}

output "region" {
  description = "Configured AWS Region."
  value       = var.aws_region
}
