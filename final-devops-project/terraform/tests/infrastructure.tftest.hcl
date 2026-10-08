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
}
