# Terraform Remote State Controls (AWS)

## Scope
Applies to Terraform state for AWS account 460742884765 in us-west-2.

## Control Summary
- S3 remote state bucket: versioned, encrypted with CMK (KMS), public access blocked.
- Bucket policy: enforces TLS and SSE-KMS requirements for object writes.
- DynamoDB lock table: used for state locking to prevent concurrent writes.
- KMS CMK: key rotation enabled; key policy grants required principals.

## Evidence Points
- S3 bucket exists: nvc-terraform-state-460742884765-usw2
- DynamoDB table exists: nvc-terraform-locks-usw2
- KMS alias exists: alias/nvc-terraform-backend

## Operational Notes
- Bootstrap repo remains local-state by design to avoid self-referential backend dependency.
- All other Terraform stacks use the remote backend.
