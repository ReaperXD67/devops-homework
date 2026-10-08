# These are mock-provider assertions; no AWS calls or resources are created.
mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "aman-scaler-s18-mocked"
      arn = "arn:aws:s3:::aman-scaler-s18-mocked"
    }
  }
}

run "private_encrypted_versioned_bucket" {
  command = apply
  assert {
    condition     = aws_s3_bucket_public_access_block.demo.block_public_acls && aws_s3_bucket_public_access_block.demo.block_public_policy && aws_s3_bucket_public_access_block.demo.ignore_public_acls && aws_s3_bucket_public_access_block.demo.restrict_public_buckets
    error_message = "All four public-access protections must be enabled."
  }
  assert {
    condition     = aws_s3_bucket_versioning.demo.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must remain enabled."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.demo.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Server-side encryption must remain enabled."
  }
  assert {
    condition     = aws_s3_bucket.demo.force_destroy == false
    error_message = "Destroy must refuse a non-empty bucket."
  }
  assert {
    condition     = jsondecode(aws_s3_bucket_policy.tls_only.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The policy must deny requests that do not use TLS."
  }
}

run "reject_unsafe_bucket_prefix" {
  command = plan
  variables {
    bucket_prefix = "INVALID_PREFIX"
  }
  expect_failures = [var.bucket_prefix]
}
