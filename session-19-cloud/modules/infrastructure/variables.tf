variable "project_name" {
  description = "Short lowercase project identifier used in resource names."
  type        = string
  default     = "scaler-cloud"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "Use 3-25 lowercase letters, digits or hyphens, beginning with a letter."
  }
}

variable "allowed_http_cidr" {
  description = "The learner's IPv4 /32; the default is a non-routable documentation address."
  type        = string
  default     = "203.0.113.10/32"
  validation {
    condition     = can(cidrnetmask(var.allowed_http_cidr)) && can(regex("/32$", var.allowed_http_cidr))
    error_message = "Use your single public IPv4 address with /32, never 0.0.0.0/0."
  }
}

variable "instance_type" {
  description = "x86_64 EC2 size; price and availability depend on the account and Region."
  type        = string
  default     = "t3.micro"
  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Choose t3.micro, t3.small or t3.medium to match the x86_64 image."
  }
}

variable "vpc_cidr" {
  description = "Private address range for this dedicated lab VPC."
  type        = string
  default     = "10.42.0.0/16"
  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 0)) && can(regex("/16$", var.vpc_cidr))
    error_message = "Supply a valid IPv4 /16 network."
  }
}
