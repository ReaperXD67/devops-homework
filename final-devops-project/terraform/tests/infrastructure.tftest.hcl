mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
  mock_data "aws_availability_zones" {
    defaults = { names = ["ap-south-1a"] }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "aman-scaler-final-mocked"
      arn = "arn:aws:s3:::aman-scaler-final-mocked"
    }
  }
  mock_resource "aws_instance" {
    defaults = { id = "i-0123456789abcdef0", public_ip = "203.0.113.20" }
  }
}

run "final_infrastructure_contract" {
  command = apply
  assert {
    condition     = output.bucket_name == "aman-scaler-final-mocked"
    error_message = "The final project must expose its private artifacts bucket."
  }
  assert {
    condition     = output.instance_id == "i-0123456789abcdef0"
    error_message = "The final project must expose its cloud host for SSM."
  }
  assert {
    condition     = output.application_image == "ghcr.io/reaperxd67/devops-homework@${var.image_digest}" && output.chart_source_revision == var.source_revision
    error_message = "Deployment must identify its immutable image and chart source."
  }
  assert {
    condition     = strcontains(local.bootstrap, "cluster-cidr: 10.52.0.0/16") && strcontains(local.bootstrap, "service-cidr: 10.53.0.0/16") && strcontains(local.bootstrap, "cluster-dns: 10.53.0.10")
    error_message = "Kubernetes Pod, Service and DNS ranges must not overlap the VPC."
  }
  assert {
    condition     = strcontains(local.bootstrap, "kind: HelmRelease") && strcontains(local.bootstrap, "digest: ${var.image_digest}") && strcontains(local.bootstrap, "commit: ${var.source_revision}") && length(base64encode(local.bootstrap)) <= 21844
    error_message = "The boot script must fit EC2 user data and reconcile pinned application artifacts."
  }
}

run "reject_mutable_image_reference" {
  command = plan
  variables { image_digest = "latest" }
  expect_failures = [var.image_digest]
}

run "reject_unpinned_chart_source" {
  command = plan
  variables { source_revision = "main" }
  expect_failures = [var.source_revision]
}
