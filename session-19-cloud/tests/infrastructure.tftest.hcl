# This suite exercises Terraform configuration with generated provider data only.
mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
  mock_data "aws_availability_zones" {
    defaults = { names = ["ap-south-1a", "ap-south-1b"] }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "aman-scaler-s19-mocked"
      arn = "arn:aws:s3:::aman-scaler-s19-mocked"
    }
  }
  mock_resource "aws_instance" {
    defaults = {
      id        = "i-0123456789abcdef0"
      public_ip = "203.0.113.20"
    }
  }
}

run "module_contract" {
  command = apply
  assert {
    condition     = output.website_url == "http://203.0.113.20"
    error_message = "The website output must be derived from the instance IP."
  }
  assert {
    condition     = output.bucket_name == "aman-scaler-s19-mocked"
    error_message = "The bucket output must be wired through the module."
  }
  assert {
    condition     = output.instance_id == "i-0123456789abcdef0"
    error_message = "The instance output must support SSM access."
  }
}
