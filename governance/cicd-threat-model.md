# CI/CD Threat Model (Terraform via GitHub Actions)

## Assets
- AWS credentials (OIDC session tokens)
- Terraform state (S3 + DynamoDB)
- Infrastructure definitions (repo content)

## Key Threats and Controls
- Token theft
  - Short-lived OIDC tokens
  - Restrict trust to repo + branch
- Unauthorized deploys from unreviewed code
  - Branch protection on main
  - Require PR reviews
  - Require status checks
- Excessive cloud permissions
  - Role permissions scoped to backend resources
  - Separate roles for future stacks (network, security, apps)
- Supply chain risk
  - Pin action major versions
  - Use protected branches
  - Consider signed commits and dependency scanning

## Deployment Rules
- PRs run plan/validate without backend access.
- Push to main runs apply.
- Apply should be gated via GitHub Environment approvals (prod).
