# Terraform S3 demo

**Aman Kumar · Enrollment 10275**

This project declares one private S3 bucket with versioning, SSE-S3 encryption, disabled ACLs, all four public-access blocks and a bucket policy that denies unencrypted HTTP transport. Terraform adds a unique suffix to `bucket_prefix`. `force_destroy = false` prevents removal of a bucket containing objects.

**Execution status:** code and local checks are complete; AWS provisioning is pending. [Actual local validation and mock-test transcript](../evidence/validation.txt). Every output identified as mocked in the tests is synthetic test data. No AWS console screenshot, bucket creation or successful live apply is claimed.

## Files

| File | Purpose |
| --- | --- |
| `provider.tf` | Terraform/AWS provider constraints, Region and common tags |
| `variables.tf` | Typed inputs and bucket-prefix validation |
| `terraform.tfvars` | Public example values only |
| `main.tf` | Bucket, access block, ownership, encryption, versioning and TLS policy |
| `outputs.tf` | Bucket name, ARN and Region |
| `.terraform.lock.hcl` | Selected provider version and package checksums |
| `tests/security.tftest.hcl` | Security controls and invalid-input tests using a mocked AWS provider |

## Local checks — no AWS account needed

```powershell
cd session-18-terraform/terraform-s3-demo
terraform init -no-color
terraform fmt -check -recursive
terraform validate -no-color
terraform test -no-color
```

`init` downloads the provider and selects the backend. `fmt` enforces canonical formatting. `validate` checks configuration and provider schemas. `test` asserts privacy, encryption, versioning, TLS enforcement and protection against non-empty deletion, then confirms an invalid prefix is rejected. Passing these checks does not check IAM permissions or global bucket-name availability in AWS.

## Live workflow — run after AWS setup

Follow [AWS setup](../AWS-SETUP.md), select the learning account and start in this folder. The following are **commands to execute later**, not recorded success output:

```powershell
$env:AWS_PROFILE = 'scaler-lab'
aws sts get-caller-identity
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=lab.tfplan
terraform show lab.tfplan
terraform apply lab.tfplan
terraform show
terraform output
$bucketName = terraform output -raw bucket_name
aws s3api get-public-access-block --bucket $bucketName
aws s3api get-bucket-versioning --bucket $bucketName
aws s3api get-bucket-encryption --bucket $bucketName
terraform plan
terraform destroy
terraform state list
```

Inspect the saved plan before apply. It should describe the bucket and five related resources. `show` prints the plan or current state; `output` reads declared outputs from state. A second plan should report no changes after a successful, unchanged deployment. `destroy` asks for confirmation and removes only resources tracked in this project's state. An empty `state list` verifies cleanup. Leave the bucket empty for this exercise so versioned objects do not block teardown.

Capture real plan/apply, configuration checks, outputs and destroy results in `../evidence/aws-live.txt` and console screenshots under `../evidence/` once run. Review logs before publication: redact account IDs, role ARNs, addresses or names that should not be public, and never commit credentials, binary plan files or Terraform state. Until that evidence exists, the live portion remains pending.

## State and dependencies

Each resource references `aws_s3_bucket.demo.id`, so Terraform creates the bucket before its configuration and removes dependent configuration before removing the bucket. Local state is suitable for this one-person lab only. A shared deployment should use a separately bootstrapped, encrypted remote backend with access control, versioning and state locking; the bucket managed here is not its own backend.

S3 versioning preserves previous objects but does not replace backups or retention planning. [AWS versioning documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html). New objects use the configured server-side encryption. [AWS encryption documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html).
