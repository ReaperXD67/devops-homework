# Terraform S3 demo

**Aman Kumar · Enrollment 10275**

This project declares one private S3 bucket with versioning, SSE-S3 encryption, disabled ACLs, all four public-access blocks and a bucket policy that denies unencrypted HTTP transport. Terraform adds a unique suffix to `bucket_prefix`. `force_destroy = false` prevents removal of a bucket containing objects.

**Live execution completed on 14 October 2026 in ap-south-1.** The [AWS transcript](../evidence/aws-live.txt) records six resources created, successful AWS configuration checks, a no-change refresh plan and all six resources removed. Empty Terraform state and the expected `HeadBucket` 404 confirm cleanup. The [earlier local validation and mock-test transcript](../evidence/validation.txt) remains separate; its mocked values are synthetic and did not create resources.

| Verification | Actual result |
| --- | --- |
| Public-access block | All four settings `true` |
| Versioning | `Enabled` |
| Encryption | `AES256` / SSE-S3 |
| Ownership | `BucketOwnerEnforced`, disabling ACLs |
| Bucket policy | `DenyInsecureTransport` rejects non-TLS requests |
| Repeat plan | `No changes. Your infrastructure matches the configuration.` |
| Cleanup | 6 destroyed, empty state, bucket returns 404 |

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

## Live workflow

Follow [AWS setup](../AWS-SETUP.md), select the learning account and start in this folder. Use the [temporary-credential helper](../../scripts/terraform-login.py) for Terraform commands so the browser-login session supplies credentials to the pinned AWS provider. The helper retains Terraform's normal plan review, prompts and exit codes.

```powershell
$env:AWS_PROFILE = 'scaler-lab'
$env:AWS_REGION = 'ap-south-1'
$awsCliPath = Join-Path $env:LOCALAPPDATA 'Programs/Amazon/AWSCLIV2/aws.exe'
& $awsCliPath login --profile scaler-lab --region ap-south-1
& $awsCliPath sts get-caller-identity
python ../../scripts/terraform-login.py -- init
python ../../scripts/terraform-login.py -- fmt -recursive
python ../../scripts/terraform-login.py -- validate
python ../../scripts/terraform-login.py -- plan '-out=live.tfplan'
python ../../scripts/terraform-login.py -- show live.tfplan
python ../../scripts/terraform-login.py -- apply live.tfplan
python ../../scripts/terraform-login.py -- show
python ../../scripts/terraform-login.py -- output
$bucketName = python ../../scripts/terraform-login.py -- output -raw bucket_name
& $awsCliPath s3api get-public-access-block --bucket $bucketName
& $awsCliPath s3api get-bucket-versioning --bucket $bucketName
& $awsCliPath s3api get-bucket-encryption --bucket $bucketName
& $awsCliPath s3api get-bucket-ownership-controls --bucket $bucketName
& $awsCliPath s3api get-bucket-policy --bucket $bucketName
python ../../scripts/terraform-login.py -- plan -detailed-exitcode

# Review and apply the cleanup plan used in the recorded run.
python ../../scripts/terraform-login.py -- plan -destroy '-out=destroy.tfplan'
python ../../scripts/terraform-login.py -- show destroy.tfplan
python ../../scripts/terraform-login.py -- apply destroy.tfplan
python ../../scripts/terraform-login.py -- state list
& $awsCliPath s3api head-bucket --bucket $bucketName
# Confirm the empty state has nothing left to destroy.
python ../../scripts/terraform-login.py -- destroy
```

Inspect the saved plan before apply: it contains the bucket and five related resources. `show` prints the plan or current state; `output` reads declared outputs from state. With `-detailed-exitcode`, an unchanged plan returns 0, proposed changes return 2 and errors return 1. Cleanup removes resources tracked in this project's state. Leave the bucket empty for this exercise so versioned objects do not block teardown. The `head-bucket` check is expected to fail with 404 after deletion; the recorded AWS CLI exit code was 254. A subsequent `terraform destroy` confirmed that no objects remained to destroy.

The [live transcript](../evidence/aws-live.txt) contains the actual plan, apply, show, outputs, five AWS configuration checks, refresh and cleanup results. Terraform state, binary plans and credentials stay outside Git. Re-running this workflow creates a new bucket; the previously verified bucket has been deleted.

![Actual live AWS command output](../../output/playwright/session-18-aws.png)

## State and dependencies

Each resource references `aws_s3_bucket.demo.id`, so Terraform creates the bucket before its configuration and removes dependent configuration before removing the bucket. Local state is suitable for this one-person lab only. A shared deployment should use a separately bootstrapped, encrypted remote backend with access control, versioning and state locking; the bucket managed here is not its own backend.

S3 versioning preserves previous objects but does not replace backups or retention planning. [AWS versioning documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html). New objects use the configured server-side encryption. [AWS encryption documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html).
