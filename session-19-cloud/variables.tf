variable "aws_region" {
  description = "AWS Region used for all lab resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Identifier for this isolated lab."
  type        = string
  default     = "aman-scaler-s19"
}

variable "allowed_http_cidr" {
  description = "Replace the documentation address with your public IPv4 /32 before applying."
  type        = string
  default     = "203.0.113.10/32"
}

variable "instance_type" {
  description = "x86_64 instance class."
  type        = string
  default     = "t3.micro"
}
