---
name: review-pr
description: Multi-perspective PR review combining security, compliance, architecture, and documentation agents (multi-cloud, multi-framework)
---

## Overview

This compound workflow invokes multiple agent perspectives to provide a comprehensive PR review. It combines findings from security, compliance, architecture, and documentation reviews into a single consolidated report.

**Adapts to:** FedRAMP, GovRAMP, CMMC | Azure, AWS, GCP

## Required Context

**CRITICAL: Before starting PR review, you MUST read the session context:**

1. Read `/.claude/session-context.md` - Current engagement configuration
2. Read the cloud provider data file:
   - Azure: `/.claude/data/clouds/azure.yaml`
   - AWS: `/.claude/data/clouds/aws.yaml`
   - GCP: `/.claude/data/clouds/gcp.yaml`
3. Read the framework data file:
   - FedRAMP: `/.claude/data/frameworks/fedramp.yaml`
   - GovRAMP: `/.claude/data/frameworks/govramp.yaml`
   - CMMC: `/.claude/data/frameworks/cmmc.yaml`

If no session context exists, inform the user to run `/init` first.

## Instructions

When reviewing a PR, perform the following analysis in sequence:

### Step 1: Gather Context

1. Identify the files changed in the PR
2. Read the PR description and any linked issues
3. Understand the purpose and scope of the changes
4. Verify session context for cloud provider and compliance framework

### Step 2: Security Review

Analyze from a security perspective (adapt checks to configured cloud):

**All Clouds:**
- **Encryption:** TLS 1.2+, encryption at rest with managed keys
- **Network:** Private connectivity, no public access
- **Access Control:** Least privilege, managed/workload identities
- **Secrets:** No hardcoded credentials, secrets manager usage
- **Logging:** Audit logging configured
- **Vulnerabilities:** Check for common misconfigurations

**Azure-Specific:**
- Private endpoints configured
- Diagnostic settings to Log Analytics
- Key Vault for secrets
- Managed Identity usage

**AWS-Specific:**
- VPC endpoints configured
- CloudWatch/CloudTrail logging
- Secrets Manager or SSM Parameter Store
- IAM roles with scoped policies

**GCP-Specific:**
- Private Service Connect configured
- Cloud Logging/Audit Logs
- Secret Manager usage
- Workload Identity for service accounts

Flag any findings as Critical/High/Medium/Low severity.

### Step 3: Compliance Review

Analyze from the configured framework's compliance perspective:

**FedRAMP/GovRAMP (NIST 800-53):**
- **Control Mapping:** Which NIST 800-53 controls are affected?
- **Implementation Status:** Does this implement, modify, or impact controls?
- **Gap Analysis:** Does this close any gaps? Create new gaps?
- **SSP Impact:** What SSP sections need updates?
- **Evidence:** Where is the evidence for auditors?

**CMMC (NIST 800-171):**
- **Practice Mapping:** Which CMMC practices are affected?
- **CUI Impact:** Does this affect the CUI boundary?
- **Assessment Scope:** Does this change the assessment scope?
- **SSP Impact:** What SSP sections need updates?
- **SPRS Score Impact:** Any effect on SPRS score?

### Step 4: Architecture Review

Analyze from a Terraform architecture perspective (adapt to configured cloud):

- **Patterns:** Does it follow established module patterns?
- **Naming:** Are naming conventions followed?
- **Variables/Outputs:** Are standard variables and outputs present?
- **Reusability:** Is it multi-client ready?
- **State Management:** Any state concerns?
- **Provider Compatibility:** Version constraints appropriate?

**Cloud-Specific Checks:**

| Aspect | Azure | AWS | GCP |
|--------|-------|-----|-----|
| Provider | azurerm | aws | google |
| Region var | location | region | region |
| Grouping | resource_group_name | tags | project_id |
| Metadata | tags | tags | labels (lowercase) |

### Step 5: Documentation Review

Analyze documentation needs (adapt to configured framework):

- **Module README:** Does the module have documentation?
- **Control Mappings:** Are controls/practices documented in comments/README?
- **SSP Updates:** What needs to be added to the SSP?
- **Architecture Diagrams:** Any diagram updates needed?

**Framework-Specific SSP Sections:**

| FedRAMP/GovRAMP | CMMC |
|-----------------|------|
| Section 13.X (Control Families) | Section 3.X (Security Requirements) |
| FIPS 199 Categorization | CUI Boundary Description |
| Appendix A (Network Diagram) | Appendix A (Network Topology) |
| Appendix C (Ports/Protocols) | Appendix C (Asset Inventory) |

## Output Format

```markdown
# PR Review: [PR Title/Number]

## Session Context
- **Cloud Provider:** [Azure/AWS/GCP]
- **Compliance Framework:** [FedRAMP/GovRAMP/CMMC] [Level]
- **Control/Practice Count:** [Number]

## Summary
**Overall Verdict:** Approve / Request Changes / Needs Discussion
**Risk Level:** Low / Medium / High

**Quick Stats:**
| Category | Findings |
|----------|----------|
| Security | X Critical, X High, X Medium |
| Compliance | X controls/practices affected, X gaps |
| Architecture | X issues |
| Documentation | X updates needed |

---

## Security Findings

### Critical/High Severity
[List any critical or high severity findings with remediation]

### Medium/Low Severity
[List medium and low findings]

### Cloud-Specific Security Checklist
- [ ] No hardcoded secrets
- [ ] Encryption at rest enabled (CMK/KMS/CMEK)
- [ ] TLS 1.2+ enforced
- [ ] Public access disabled
- [ ] Audit logging configured
- [ ] Least privilege IAM/RBAC
- [ ] Private connectivity (endpoint/VPC endpoint/PSC)

### Security Verdict
[Pass / Needs Changes / Blocker]

---

## Compliance Assessment

### Control/Practice Mappings

**For FedRAMP/GovRAMP:**
| Control ID | Control Name | Impact | Status |
|------------|--------------|--------|--------|
| SC-8 | Transmission Confidentiality | Implemented | Good |
| AU-2 | Audit Events | Modified | Verify |

**For CMMC:**
| Practice ID | Practice Name | Impact | Status |
|-------------|---------------|--------|--------|
| 3.13.8 | Transmission Confidentiality | Implemented | Good |
| 3.3.1 | Audit Events | Modified | Verify |

### Gap Analysis Impact
- Gaps Closed: [List]
- Gaps Created: [List]
- No Impact: [List]

### SSP Updates Required
- [ ] Section X.X: [Update description]
- [ ] Appendix Y: [Update description]

### CMMC-Specific (if applicable)
- **CUI Boundary Change:** Yes/No
- **SPRS Score Impact:** None/Positive/Negative
- **Assessment Scope Change:** Yes/No

### Compliance Verdict
[Pass / Needs Updates / Blocker]

---

## Architecture Assessment

### Pattern Compliance
| Aspect | Status | Notes |
|--------|--------|-------|
| File Structure | Pass/Fail | |
| Naming Conventions | Pass/Fail | |
| Required Variables | Pass/Fail | |
| Required Outputs | Pass/Fail | |
| Tags/Labels | Pass/Fail | |

### Cloud-Specific Requirements
**Azure:**
- [ ] resource_group_name variable present
- [ ] log_analytics_workspace_id for diagnostics
- [ ] Tags include ComplianceFramework

**AWS:**
- [ ] kms_key_arn for encryption
- [ ] VPC/subnet variables for endpoints
- [ ] Tags include ComplianceFramework

**GCP:**
- [ ] project_id variable present
- [ ] logging_bucket_name for audit logs
- [ ] Labels are lowercase

### Code Quality
[Assessment of code quality, readability, maintainability]

### Architecture Verdict
[Pass / Needs Changes / Blocker]

---

## Documentation Assessment

### Updates Required
- [ ] Module README
- [ ] SSP Section X
- [ ] Network Diagram
- [ ] Control/Practice Implementation Comments

### Documentation Verdict
[Pass / Needs Updates]

---

## Required Changes (Blockers)

1. **[Category]:** [Required change description]
   ```hcl
   # Suggested fix
   ```

2. **[Category]:** [Required change description]

## Recommended Changes (Non-blocking)

1. **[Category]:** [Suggestion]
2. **[Category]:** [Suggestion]

---

## Approval Checklist

### All Frameworks
- [ ] All security findings addressed
- [ ] Compliance controls/practices properly implemented
- [ ] Architecture patterns followed
- [ ] Documentation updated
- [ ] CI/CD checks passing

### Framework-Specific
**FedRAMP/GovRAMP:**
- [ ] NIST 800-53 controls mapped
- [ ] SSP sections identified for update
- [ ] Evidence locations documented

**CMMC:**
- [ ] NIST 800-171 practices mapped
- [ ] CUI boundary unchanged or documented
- [ ] Assessment scope impact evaluated

**Reviewer Notes:**
[Any additional context or considerations]
```
