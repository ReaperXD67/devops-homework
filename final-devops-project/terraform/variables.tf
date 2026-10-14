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

variable "source_revision" {
  description = "Reviewed existing repository commit containing the Helm chart; no future commit is required at boot."
  type        = string
  default     = "77166ce59eff8a2c6e02e189b56fe995c18ed1f0"
  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.source_revision))
    error_message = "Pin the chart source to a full Git commit SHA."
  }
}

variable "image_digest" {
  description = "Previously scanned application image digest recorded in the GitOps evidence."
  type        = string
  default     = "sha256:bddd87c63b22371d1724581bd475ae584f774199dd828f92eaf87201d115e041"
  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.image_digest))
    error_message = "Use an immutable sha256 image digest."
  }
}

variable "k3s_version" {
  description = "Pinned K3s release installed by its matching official install script."
  type        = string
  default     = "v1.35.9+k3s1"
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+\\+k3s[0-9]+$", var.k3s_version))
    error_message = "Use an exact K3s version such as v1.35.9+k3s1."
  }
}

variable "flux_version" {
  description = "Pinned Flux CLI/controllers release."
  type        = string
  default     = "2.9.6"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.flux_version))
    error_message = "Use a numeric Flux release version."
  }
}

variable "helm_version" {
  description = "Pinned Helm CLI for release inspection. Flux performs the installation."
  type        = string
  default     = "3.19.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.helm_version))
    error_message = "Use a numeric Helm release version."
  }
}
