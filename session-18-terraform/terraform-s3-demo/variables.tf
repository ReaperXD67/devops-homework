variable "aws_region" {
  description = "AWS Region for this demonstration."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Terraform appends a unique suffix to this bucket prefix."
  type        = string
  default     = "aman-scaler-s18-"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,35}-$", var.bucket_prefix))
    error_message = "Use 4-37 lowercase letters, digits or hyphens, beginning with a letter and ending in a hyphen."
  }
}
