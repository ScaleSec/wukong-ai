# GovRAMP Compliance Workflow System

## Project Context

This is a multi-agent workflow system for building and maintaining GovRAMP-compliant Azure Landing Zone Terraform codebases. It provides specialized Claude Code agents for compliance, architecture, security, project management, and documentation.

**Target Compliance:** GovRAMP Moderate (NIST 800-53 Rev 5, 319 controls)

## Available Agents

| Command | Agent | Purpose |
|---------|-------|---------|
| `/pm` | Project Manager | SOW analysis, scope/timeline, deliverable tracking |
| `/compliance` | GovRAMP Compliance | NIST 800-53 control mapping, gap analysis |
| `/architect` | Terraform Architect | Module design, patterns, conventions |
| `/security` | Security Reviewer | Vulnerability review, secure configuration |
| `/docs` | Documentation | SSP maintenance, policy updates |
| `/cicd` | CI/CD Operations | Pipeline troubleshooting, deployments |

## Compound Workflows

| Command | Purpose |
|---------|---------|
| `/review-pr` | Multi-perspective PR review from all agents |
| `/new-module` | Guided compliant Terraform module creation |

## Key Files Reference

When working with client infrastructure repositories, agents should reference:

```
/docs/govramp-gap.md           # Compliance gap analysis
/docs/system-security-plan.md  # SSP with control implementations
/docs/policies/*.md            # Policy documents (AC-1, AU-1, etc.)
/docs/poam.md                  # Plan of Action and Milestones
/docs/risk-assessment.md       # Risk register
/modules/*/                    # Terraform modules
/.github/workflows/            # CI/CD pipelines
```

## Terraform Coding Standards

### Naming Conventions

- **Directories:** kebab-case (`key-vault`, `network-security-group`)
- **Resources:** `${var.project_name}-${var.environment}-resourcetype`
- **Variables:** snake_case
- **Files:** `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

### Required Tags

All resources must include:
```hcl
tags = merge(var.tags, {
  Environment         = var.environment
  ComplianceFramework = "GovRAMP"
  ManagedBy          = "Terraform"
})
```

### Required Module Outputs

```hcl
output "id" {
  description = "Resource ID"
}

output "name" {
  description = "Resource name"
}
```

## GovRAMP Compliance Requirements

### Always Verify

1. **Encryption:** TLS 1.2+ in transit, AES-256 at rest
2. **Network Isolation:** Private endpoints, no public access
3. **Logging:** Diagnostic settings to Log Analytics, 90-day retention
4. **Access Control:** RBAC with least privilege, managed identities
5. **Secrets:** Key Vault for all secrets, no hardcoded credentials

### Control Family Focus

| Priority | Family | Key Controls |
|----------|--------|--------------|
| Critical | SC | Encryption, network isolation |
| Critical | AC | RBAC, least privilege |
| Critical | AU | Logging, monitoring, retention |
| High | IA | Authentication, MFA, OIDC |
| High | SI | Defender, vulnerability scanning |
| High | CM | IaC, change control |

## Usage Instructions

1. **New Module:** Use `/new-module` for guided creation with compliance
2. **PR Review:** Use `/review-pr` before merging any infrastructure changes
3. **Compliance Check:** Use `/compliance` when unsure about control requirements
4. **SOW Analysis:** Use `/pm` to analyze new client SOWs
5. **Security Audit:** Use `/security` for vulnerability assessment

## Documentation

See `agentic-plan.md` for complete agent system documentation including:
- Detailed agent personas and responsibilities
- Workflow diagrams
- Control family reference
- Usage examples
