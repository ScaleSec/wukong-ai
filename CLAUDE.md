# Compliance Workflow System

**Multi-Cloud, Multi-Framework Agentic Compliance Automation**

## Project Context

This is a multi-agent workflow system for building and maintaining compliant cloud infrastructure using Terraform. It provides specialized Claude Code agents for compliance, architecture, security, project management, and documentation.

**Supported Frameworks:**
- FedRAMP (Low/Moderate/High) - NIST 800-53 Rev 5
- GovRAMP (Low/Moderate/High) - NIST 800-53 Rev 5
- CMMC (Level 1/2/3) - NIST 800-171

**Supported Cloud Providers:**
- Azure (azurerm provider)
- AWS (aws provider)
- GCP (google provider)

## Getting Started

### Session Configuration

**Start every engagement with `/init`** to configure:
1. Cloud provider (Azure, AWS, or GCP)
2. Compliance framework (FedRAMP, GovRAMP, or CMMC)
3. Baseline level

This creates a session context file that all agents reference.

## Available Agents

| Command | Agent | Purpose |
|---------|-------|---------|
| `/init` | Session Config | Configure cloud provider and compliance framework |
| `/pm` | Project Manager | SOW analysis, scope tracking, deliverable management |
| `/compliance` | Compliance Expert | Control mapping, gap analysis, SSP alignment |
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

### Session Context
```
/.claude/session-context.md     # Current engagement configuration (created by /init)
```

### Framework Data
```
/.claude/data/frameworks/fedramp.yaml   # FedRAMP control data
/.claude/data/frameworks/govramp.yaml   # GovRAMP control data
/.claude/data/frameworks/cmmc.yaml      # CMMC practice data
```

### Cloud Provider Data
```
/.claude/data/clouds/azure.yaml   # Azure patterns and mappings
/.claude/data/clouds/aws.yaml     # AWS patterns and mappings
/.claude/data/clouds/gcp.yaml     # GCP patterns and mappings
```

### Cloud-Specific Examples
```
/examples/azure/    # Azure Terraform patterns
/examples/aws/      # AWS Terraform patterns
/examples/gcp/      # GCP Terraform patterns
```

### Client Infrastructure (typical structure)
```
/docs/gap-analysis.md          # Compliance gap analysis
/docs/system-security-plan.md  # SSP with control implementations
/docs/policies/*.md            # Policy documents
/docs/poam.md                  # Plan of Action and Milestones
/docs/risk-assessment.md       # Risk register
/modules/*/                    # Terraform modules
/.github/workflows/            # CI/CD pipelines
```

## Terraform Coding Standards

### Naming Conventions

- **Directories:** kebab-case (`key-vault`, `kms-key`, `secret-manager`)
- **Resources:** `${var.project_name}-${var.environment}-resourcetype`
- **Variables:** snake_case
- **Files:** `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`

### Required Variables (Cloud-Specific)

**Azure:**
```hcl
variable "project_name" {}
variable "environment" {}
variable "location" {}
variable "resource_group_name" {}
variable "compliance_framework" {}
variable "tags" { default = {} }
```

**AWS:**
```hcl
variable "project_name" {}
variable "environment" {}
variable "region" {}
variable "compliance_framework" {}
variable "tags" { default = {} }
```

**GCP:**
```hcl
variable "project_name" {}
variable "project_id" {}
variable "environment" {}
variable "region" {}
variable "compliance_framework" {}
variable "labels" { default = {} }  # Must be lowercase
```

### Compliance Tags/Labels

**Azure/AWS (tags):**
```hcl
tags = merge(var.tags, {
  Environment         = var.environment
  ComplianceFramework = var.compliance_framework
  ManagedBy           = "Terraform"
})
```

**GCP (labels - lowercase only):**
```hcl
labels = merge(var.labels, {
  environment          = lower(var.environment)
  compliance-framework = lower(replace(var.compliance_framework, " ", "-"))
  managed-by           = "terraform"
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

## Compliance Requirements

### Always Verify (All Frameworks)

1. **Encryption:** TLS 1.2+ in transit, encryption at rest with managed keys
2. **Network Isolation:** Private connectivity, no public access
3. **Logging:** Audit logging with 90-day minimum retention
4. **Access Control:** Least privilege, managed/workload identities
5. **Secrets:** Secrets manager for all credentials, no hardcoded secrets

### Control Family Focus

| Priority | NIST 800-53 | NIST 800-171 | Key Focus |
|----------|-------------|--------------|-----------|
| Critical | SC | 3.13 | Encryption, network isolation |
| Critical | AC | 3.1 | Access control, least privilege |
| Critical | AU | 3.3 | Logging, monitoring, retention |
| High | IA | 3.5 | Authentication, MFA, OIDC |
| High | SI | 3.14 | Security monitoring, vulnerability scanning |
| High | CM | 3.4 | Configuration management, IaC |

### Framework-Specific Notes

**FedRAMP/GovRAMP:**
- SSP follows NIST 800-53 Rev 5 structure
- Authorization phases: Preparation, Readiness, Assessment, Authorization, ConMon

**CMMC:**
- SSP follows NIST 800-171 structure
- Must define CUI boundary clearly
- SPRS score tracking required
- Assessment type varies by level (Self for L1, C3PAO for L2+)

## Usage Instructions

1. **New Engagement:** Run `/init` to configure cloud and framework
2. **New Module:** Use `/new-module` for guided creation with compliance
3. **PR Review:** Use `/review-pr` before merging infrastructure changes
4. **Compliance Check:** Use `/compliance` for control requirements
5. **SOW Analysis:** Use `/pm` to analyze client SOWs
6. **Security Audit:** Use `/security` for vulnerability assessment

## Documentation

See `agentic-plan.md` for complete agent system documentation including:
- Detailed agent personas and responsibilities
- Workflow diagrams
- Control family reference
- Usage examples
