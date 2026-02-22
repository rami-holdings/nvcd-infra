# Shield Sprint (Edge-to-Cloud Baseline)

## What’s included
- Cloudflare edge baseline (DNSSEC, WAF baseline, rate limits, bot posture by plan).
- Origin protection: Cloudflare injects verification header; origin enforces it.
- Terraform-managed AWS telemetry archive for Cloudflare metrics snapshots.
- Keyless CI/CD with GitHub OIDC and gated applies.
- Governance pack: state controls, identity model, CI/CD threat model, break-glass/SSO checklist.

## Outcomes
- “Direct-to-origin blocked” posture (origin header enforcement).
- Weekly/Monthly security scorecard from Cloudflare metrics.
- Auditable, PR-gated infra changes with approval-gated apply.

## Delivery pattern
- Week 1: Edge baseline + origin protection + telemetry bucket.
- Week 2: Scorecard automation + governance artifacts handed off.
