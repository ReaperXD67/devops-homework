# AWS setup for the remaining live exercises

**Status: pending, by request.** The repository is prepared and locally validated. Sessions 18, 19 and the final project's cloud infrastructure can be executed after a learning account is available.

## 1. Prepare a learning account

Create or select an AWS learning/sandbox account, enable MFA, and configure a budget notification before starting EC2. Use IAM Identity Center to give Aman Kumar a temporary-credential role named, for example, `ScalerLab`. Use the root identity only for account tasks that require it; do not create root access keys. [AWS IAM security guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html).

The account administrator needs to enable an **organization instance** of IAM Identity Center and assign the learner a permission set for this account. The SSO start URL and the SSO Region come from that setup; the SSO Region can differ from the resource Region `ap-south-1`.

## 2. Install AWS CLI v2 and configure SSO

Install the official [AWS CLI v2 for Windows](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), then reopen PowerShell. Configure a named profile and complete the browser login:

```powershell
aws --version
aws configure sso --profile scaler-lab
# Supply your own SSO session name, start URL and SSO Region.
# Select your learning account and ScalerLab permission set.
# Default client Region: ap-south-1. Output format: json.
aws sso login --profile scaler-lab
$env:AWS_PROFILE = 'scaler-lab'
$env:AWS_REGION = 'ap-south-1'
aws sts get-caller-identity
```

SSO login stores short-lived authentication locally. Terraform can use this profile through its normal AWS credential chain. Expired sessions can be refreshed with `aws sso login --profile scaler-lab`. Keep login codes and local AWS files out of Git. [AWS CLI SSO instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html).

## 3. Permissions the lab role needs

Ask the account administrator for a dedicated lab permission set. Review the actual Terraform plan and audit denied actions rather than granting permanent administrator access.

| Scope | Required capabilities |
| --- | --- |
| S3 buckets named `aman-scaler-s18-*`, `aman-scaler-s19-*`, `aman-scaler-final-*` | Create/delete and read/configure bucket versioning, encryption, public-access block, ownership, policy and tags; read bucket configuration during refresh |
| EC2 in `ap-south-1`, dedicated learning VPC | Describe resources; create/delete VPC, subnet, Internet Gateway, route table, routes, associations, security group/rules, EC2 instance, encrypted gp3 EBS volume and tags; modify VPC DNS attributes; terminate instances during cleanup |
| IAM roles/profiles with `aman-scaler-s19-*` or `aman-scaler-final-*` prefixes | Create/read/delete role and instance profile, add/remove role from profile, attach/detach only `AmazonSSMManagedInstanceCore`, maintain the lab bucket read-only inline policy, tag resources |
| `iam:PassRole` | Limit to those lab EC2 roles and the `ec2.amazonaws.com` service |
| SSM parameter | Read `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64` |
| SSM administration | Describe managed instances and start/resume/terminate the learner's own sessions against lab-tagged instances |

Some EC2 discovery and create actions require `Resource: "*"`; constrain supported actions by Region, request tags and resource tags where possible. The application's instance role has Systems Manager access and read-only access to its own artifact bucket. It has no embedded access keys. This is a permissions checklist, not a tested complete IAM deployment policy; the administrator must account for the learning account's SCPs and permission boundaries.

## 4. Run the cloud exercises

Start with [Session 18 S3](terraform-s3-demo/README.md#live-workflow--run-after-aws-setup), then [Session 19](../session-19-cloud/README.md#live-deployment-pending). Set `allowed_http_cidr` to your public IPv4 followed by `/32` in an ignored `local.auto.tfvars` file before the Session 19 plan. The checked-in `203.0.113.10/32` is documentation-only.

Do not run all roots just to create the same learning architecture multiple times. Session 19 and the final project's Terraform root are independent states and create separate resources. Finish and destroy Session 19 before provisioning the final environment.

EC2, EBS, public IPv4 addresses and stored S3 objects can incur charges. No free-tier eligibility is assumed. Retain a reviewable plan, capture actual evidence, then run each project's destroy workflow when finished.
