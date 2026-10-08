mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
  mock_data "aws_availability_zones" {
    defaults = { names = ["ap-south-1a"] }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "scaler-cloud-mocked"
      arn = "arn:aws:s3:::scaler-cloud-mocked"
    }
  }
}

run "network_compute_storage_security" {
  command = apply
  assert {
    condition     = aws_subnet.public.cidr_block == "10.42.1.0/24" && aws_subnet.public.vpc_id == aws_vpc.lab.id
    error_message = "The subnet must be carved from and attached to the VPC."
  }
  assert {
    condition     = aws_instance.web.subnet_id == aws_subnet.public.id && contains(aws_instance.web.vpc_security_group_ids, aws_security_group.web.id)
    error_message = "The instance must use the intended subnet and security group."
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.http.cidr_ipv4 == "203.0.113.10/32" && aws_vpc_security_group_ingress_rule.http.from_port == 80
    error_message = "Inbound HTTP must be limited to the configured /32."
  }
  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required" && aws_instance.web.root_block_device[0].encrypted
    error_message = "IMDSv2 and EBS encryption are mandatory."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.artifacts.block_public_policy && aws_s3_bucket_public_access_block.artifacts.restrict_public_buckets && aws_s3_bucket_public_access_block.artifacts.block_public_acls && aws_s3_bucket_public_access_block.artifacts.ignore_public_acls
    error_message = "The artifacts bucket must remain private."
  }
  assert {
    condition     = aws_s3_bucket_versioning.artifacts.versioning_configuration[0].status == "Enabled" && !aws_s3_bucket.artifacts.force_destroy
    error_message = "Object history and non-empty-bucket protection must remain enabled."
  }
}

run "reject_world_open_http" {
  command = plan
  variables { allowed_http_cidr = "0.0.0.0/0" }
  expect_failures = [var.allowed_http_cidr]
}

run "reject_incompatible_arm_instance" {
  command = plan
  variables { instance_type = "t4g.micro" }
  expect_failures = [var.instance_type]
}
