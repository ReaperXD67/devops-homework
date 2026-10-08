# S3 — object storage

**Aman Kumar · Enrollment 10275**

Amazon S3 stores objects in buckets. An object contains data and metadata and is addressed by a key such as `releases/app.tar.gz`; slash-separated keys are not traditional filesystem directories. Buckets provide the boundary for settings such as policy, versioning and lifecycle.

| Topic | Meaning |
| --- | --- |
| Storage classes | Standard for frequent access; Intelligent-Tiering for changing access; Standard-IA/One Zone-IA for infrequent access; Glacier classes for archives with differing retrieval behavior |
| Versioning | Keep earlier object versions after overwrites; a normal delete may add a delete marker |
| Lifecycle | Rules that transition or expire objects/versions; align them with retention needs |
| Encryption | SSE-S3 uses S3-managed encryption; SSE-KMS uses KMS keys and policy controls |
| Bucket policy | Resource policy controlling allowed/denied operations on a bucket and its objects |

Versioning protects against accidental overwrites, but retained versions still consume storage. Lifecycle rules can manage old versions. [AWS versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html). Encryption at rest and TLS in transit address different risks. [AWS encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html).

## Practical example

The [Terraform S3 demo](../../terraform-s3-demo/README.md) uses a unique bucket prefix, explicit public-access blocking, ACLs disabled through BucketOwnerEnforced, encryption and versioning. Its TLS policy is an explicit deny, so adding another allow cannot enable ordinary HTTP access.

Example uses include private build artifacts, backups, data lakes, logs and static website assets. A website requires a deliberate delivery/access design; this lab bucket is private and is not configured as a public website.

Pending commands after the live apply:

```powershell
$bucketName = terraform output -raw bucket_name
aws s3api get-bucket-versioning --bucket $bucketName
aws s3api get-bucket-encryption --bucket $bucketName
aws s3api get-public-access-block --bucket $bucketName
```

Expected configuration values are `Enabled`, `AES256`, and four `true` public-access-block flags. These are expectations derived from the code, not captured AWS output. Keep the lab bucket empty for simple, safe cleanup; versioned objects must be deliberately removed before its destroy can succeed.
