# AWS authentication and Terraform setup

**Verified 14 October 2026:** AWS CLI **2.38.0** is installed per user and browser login through `scaler-lab` works. Terraform provider **5.100.x** successfully authenticated when temporary credentials were passed privately in its child-process environment. Project READMEs contain the separate apply, verification and cleanup results.

## 1. Sign in with the existing console session

The working installation on this Windows machine is:

```powershell
$awsCliPath = 'C:\Users\Aman\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe'
& $awsCliPath --version
& $awsCliPath login --profile scaler-lab --region ap-south-1
```

Complete the browser flow using the intended AWS console identity. CLI 2.32.0 and later support this temporary-credential flow without creating an IAM user or long-term access keys. Non-root identities need the login permissions described by `SignInLocalDevelopmentAccess`, plus separate resource permissions. IAM Identity Center users should use its SSO flow instead. [AWS console-credential sign-in guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html).

The verified browser session used the account's root identity. For repeat exercises, use a dedicated temporary role or federated principal with the scoped permissions below and MFA; no root access keys are needed. [AWS IAM security guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html).

## 2. Run Terraform through the authenticated wrapper

[scripts/terraform-login.py](../scripts/terraform-login.py) invokes the AWS CLI to retrieve temporary credentials, captures that response privately, and supplies the access key, secret key and session token only through the Terraform child's environment. It writes no credential file, prints no credential values and places none in command arguments. It removes inherited profile selectors from that child and leaves the parent shell unchanged.

From the repository root:

```powershell
python scripts/terraform-login.py -- -chdir=session-18-terraform/terraform-s3-demo init
python scripts/terraform-login.py -- -chdir=session-18-terraform/terraform-s3-demo validate
python scripts/terraform-login.py -- -chdir=session-18-terraform/terraform-s3-demo plan '-out=lab.tfplan'
python scripts/terraform-login.py -- -chdir=session-18-terraform/terraform-s3-demo show lab.tfplan
# After reviewing the saved plan:
python scripts/terraform-login.py -- -chdir=session-18-terraform/terraform-s3-demo apply lab.tfplan
```

The wrapper defaults to `--profile scaler-lab --region ap-south-1`. `--` separates its options from Terraform's arguments. It discovers executables on PATH, then the per-user AWS installation and `%TEMP%\scaler-devops-tools\terraform.exe` or `%TEMP%\devops-tools\terraform.exe`. Override paths when necessary:

```powershell
python scripts/terraform-login.py --profile scaler-lab --region ap-south-1 `
  --aws 'C:\Users\Aman\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe' `
  --terraform 'C:\Users\Aman\AppData\Local\Temp\scaler-devops-tools\terraform.exe' `
  -- -chdir=session-19-cloud plan '-out=lab.tfplan'
```

Terraform retains its normal prompts and exit status; the wrapper adds no automatic approval flags. Each invocation obtains fresh credentials once. An unusually long operation can outlast those credentials, so inspect its state before retrying. Refresh an expired login with the command in step 1. After verification and cleanup, sign out with `& $awsCliPath logout --profile scaler-lab`.

## Why the credential-process bridge is not the recommended command here

AWS documents a compatibility bridge for SDKs that cannot read console-login credentials directly. This local profile is configured in `%USERPROFILE%\.aws\config`:

```ini
[profile scaler-terraform]
credential_process = "C:\Users\Aman\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe" configure export-credentials --profile scaler-lab --format process
region = ap-south-1
output = json
```

An AWS CLI STS check using `scaler-terraform` succeeded, but this machine's Terraform provider invocation returned a credential-process error. That bridge result is **not** Terraform success. The wrapper avoids the failing invocation path; its equivalent child-environment method produced a successful Session 18 plan. The underlying bridge incompatibility has not been diagnosed. [AWS login compatibility guidance](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html), [external-process configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html).

The SDK or wrapper should consume exported credential output privately; do not run that export command directly into a terminal, transcript or file. Keep AWS configuration/login caches, Terraform state and binary plans out of Git.

## 3. Scope permissions to the actual Terraform resources

This checklist comes from [the S3 configuration](terraform-s3-demo/main.tf) and [the shared infrastructure module](../session-19-cloud/modules/infrastructure/main.tf). It is not a tested complete IAM policy. Use a dedicated lab role and refine denied actions against its plan; blanket `AdministratorAccess` is not required.

| Scope | Required capabilities |
| --- | --- |
| S3 prefixes `aman-scaler-s18-*`, `aman-scaler-s19-*`, `aman-scaler-final-*` | Create/delete buckets; read/configure versioning, AES256 encryption, public-access block, ownership controls, TLS-only bucket policy and tags; object/version cleanup only when objects were written |
| Lab EC2/VPC resources in `ap-south-1` | Describe resources/availability zones; manage the VPC, subnet, Internet Gateway, routes/tables/associations, security group/rules and tags; configure VPC DNS; launch/terminate the instance and its encrypted gp3 root volume |
| IAM roles/profiles with Session 19/final prefixes | Create/read/delete the lab role/profile, add/remove the role from its profile, attach/detach only `AmazonSSMManagedInstanceCore`, and manage the inline read-only policy for that lab's artifact bucket |
| `iam:PassRole` | Restrict to the lab EC2 roles and `iam:PassedToService = ec2.amazonaws.com` |
| Public AMI parameter | `ssm:GetParameter` for `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64` in the chosen Region |
| SSM verification/administration | Inspect managed-instance status; send commands to the lab instances using required command documents and read their results. Grant session start/resume/termination only if interactive Session Manager access is used |

Some EC2 discovery/create operations require `Resource: "*"`; apply supported Region, request-tag and resource-tag conditions where possible. Account SCPs and permission boundaries may further restrict access. The **instance role** differs from the operator's provisioning role: the module gives EC2 Systems Manager access and read-only access to its own artifact bucket, without embedded keys.

## 4. Follow each project's deployment and cleanup workflow

Continue with [Session 18](terraform-s3-demo/README.md), [Session 19](../session-19-cloud/README.md) and [the final project](../final-devops-project/terraform/README.md). For Session 19/final, set your real public IPv4 `/32` as `allowed_http_cidr` in an ignored `local.auto.tfvars`; the checked-in documentation address is not a usable client address.

Each Terraform root owns independent state and separate resources. Preserve that state through verification and destroy from the same root. EC2, EBS, public IPv4 addresses and stored objects can incur charges. Capture actual results and complete each root's cleanup workflow when finished; authentication alone does not demonstrate a successful apply or destroy.
