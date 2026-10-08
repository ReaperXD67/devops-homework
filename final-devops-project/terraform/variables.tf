variable "aws_region" {
  description = "AWS Region for the final project's cloud infrastructure."
  type        = string
  default     = "ap-south-1"
}
variable "allowed_http_cidr" {
  description = "Learner's public IPv4 /32. Replace the documentation address before deployment."
  type        = string
  default     = "203.0.113.10/32"
}
