# Break-Glass and SSO Migration Checklist

## Break-Glass User (Immediate)
- Create a dedicated break-glass admin user.
- Console-only.
- Hardware MFA required.
- No access keys.
- Store recovery details offline.

## Reduce Admin User Reliance
- nvcd-admin is temporary for bootstrap.
- Enforce MFA.
- Remove long-lived access keys when CI is proven stable.
- Use role assumption for daily ops.

## IAM Identity Center (SSO) Migration (Next)
- Enable IAM Identity Center.
- Create permission sets:
  - Administrator (restricted)
  - SecurityAudit
  - InfrastructureDeploy (scoped)
- Assign identities and require MFA at IdP.
- Document onboarding/offboarding procedure.
