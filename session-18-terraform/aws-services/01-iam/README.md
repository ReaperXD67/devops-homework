# IAM — governance and access

**Aman Kumar · Enrollment 10275**

AWS Identity and Access Management controls who can perform which actions on AWS resources. Authentication establishes identity; authorization evaluates requested access.

| Concept | Meaning and example |
| --- | --- |
| User | An identity within an account; avoid long-lived access keys when federation works |
| Group | A collection of IAM users sharing policies, such as a support team |
| Role | An assumable identity with temporary credentials; suitable for EC2 and federated humans |
| Policy | JSON statements describing effect, actions, resources and optional conditions |
| Permissions | The resulting allowed actions after applicable policies and guardrails are evaluated |
| Least privilege | Grant only the required actions, resources and circumstances |

Use federation/Identity Center for people, roles for workloads, MFA, narrow permissions, access reviews and IAM Access Analyzer. Protect the account root identity and avoid its daily use. Explicit deny overrides allow; an identity without an applicable allow cannot perform the action. [AWS IAM guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html).

## Example policy and use cases

This original example permits downloading objects only within a releases prefix; it grants neither upload nor bucket listing:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::example-learning-bucket/releases/*"
  }]
}
```

Replace the example ARN before use. For listing, add `s3:ListBucket` against the bucket ARN with a prefix condition. Typical designs include an EC2 role reading its own artifact bucket, a CI role obtained through OIDC, and a support role with read-only operational access. A role trust policy defines who may assume it; its permissions policy defines what it may do afterward.

The [Session 19 module](../../../session-19-cloud/modules/infrastructure/main.tf) applies this pattern: the EC2 service assumes a role with Systems Manager access and read-only access to one lab bucket. [AWS temporary-credential guidance](https://docs.aws.amazon.com/IAM/latest/UserGuide/securing_access-keys.html).

No IAM identities have been provisioned for this research page. Live setup is covered in [AWS-SETUP.md](../../AWS-SETUP.md).
