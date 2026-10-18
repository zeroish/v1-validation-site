# v1.0.0 Validation Site

End-to-end validation that all v1.0.0 modules are reusable and work together to provision real infrastructure.

## What this validates

- DNS hosting via `dns-zone` module
- Static site hosting via `static-site` module  
- Lambda function provisioning via `lambda-function` module
- Complete infrastructure lifecycle (apply + destroy)

## Prerequisites

1. AWS credentials configured via SSO:
   ```bash
   aws sso login --sso-session gilmatic
   export AWS_PROFILE=zeroish-prod-admin
   ```

2. OpenTofu installed (or Terraform >= 1.0)

## Usage

Initialize and apply:

```bash
tofu init
tofu plan
tofu apply
```

Verify outputs:

```bash
tofu output site_url
tofu output nameservers
```

Clean up:

```bash
tofu destroy
```

## Testing checklist

- [ ] `tofu init` succeeds
- [ ] `tofu plan` shows expected resources
- [ ] `tofu apply` provisions all infrastructure
- [ ] Site is accessible via CloudFront
- [ ] Lambda function is created
- [ ] Route53 hosted zone is created
- [ ] `tofu destroy` removes all resources cleanly
