# Identity Model

## Principles
- Humans use role-based access (SSO/Identity Center planned).
- Machines use OIDC (no long-lived access keys).
- Least privilege by default.

## Current Implementation
- GitHub Actions uses OIDC to assume:
  - Role: nvc-github-terraform-deploy
  - Trust restricted to repo rami-holdings/nvcd-infra and branch main
- Terraform backend access is scoped to:
  - S3 state bucket
  - DynamoDB lock table
  - KMS key used for encryption

## Next Enhancements
- Add AWS IAM Identity Center for human access.
- Replace day-to-day IAM user usage with permission sets and roles.
- Add workflow-path restriction in trust policy using job_workflow_ref.
