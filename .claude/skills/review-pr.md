---
name: review-pr
description: Multi-perspective PR review combining security, compliance, architecture, and documentation agents
---

## Overview

This compound workflow invokes multiple agent perspectives to provide a comprehensive PR review. It combines findings from security, compliance, architecture, and documentation reviews into a single consolidated report.

## Instructions

When reviewing a PR, perform the following analysis in sequence:

### Step 1: Gather Context

1. Identify the files changed in the PR
2. Read the PR description and any linked issues
3. Understand the purpose and scope of the changes

### Step 2: Security Review

Analyze from a security perspective:

- **Encryption:** TLS 1.2+, AES-256 at rest
- **Network:** Private endpoints, no public access
- **Access Control:** RBAC, least privilege, managed identities
- **Secrets:** No hardcoded credentials, Key Vault usage
- **Logging:** Diagnostic settings configured
- **Vulnerabilities:** Check for common misconfigurations

Flag any findings as Critical/High/Medium/Low severity.

### Step 3: Compliance Review

Analyze from a GovRAMP compliance perspective:

- **Control Mapping:** Which NIST 800-53 controls are affected?
- **Implementation Status:** Does this implement, modify, or impact controls?
- **Gap Analysis:** Does this close any gaps? Create new gaps?
- **SSP Impact:** What SSP sections need updates?
- **Evidence:** Where is the evidence for auditors?

### Step 4: Architecture Review

Analyze from a Terraform architecture perspective:

- **Patterns:** Does it follow established module patterns?
- **Naming:** Are naming conventions followed?
- **Variables/Outputs:** Are standard variables and outputs present?
- **Reusability:** Is it multi-client ready?
- **State Management:** Any state concerns?
- **Provider Compatibility:** Version constraints appropriate?

### Step 5: Documentation Review

Analyze documentation needs:

- **Module README:** Does the module have documentation?
- **Control Mappings:** Are controls documented in comments/README?
- **SSP Updates:** What needs to be added to the SSP?
- **Architecture Diagrams:** Any diagram updates needed?

## Output Format

```markdown
# PR Review: [PR Title/Number]

## Summary
**Overall Verdict:** Approve / Request Changes / Needs Discussion
**Risk Level:** Low / Medium / High

**Quick Stats:**
| Category | Findings |
|----------|----------|
| Security | X Critical, X High, X Medium |
| Compliance | X controls affected, X gaps |
| Architecture | X issues |
| Documentation | X updates needed |

---

## Security Findings

### Critical/High Severity
[List any critical or high severity findings with remediation]

### Medium/Low Severity
[List medium and low findings]

### Security Verdict
[Pass / Needs Changes / Blocker]

---

## Compliance Assessment

### Control Mappings
| Control ID | Control Name | Impact | Status |
|------------|--------------|--------|--------|
| SC-8 | Transmission Confidentiality | Implemented | Good |
| AU-2 | Audit Events | Modified | Verify |

### Gap Analysis Impact
- Gaps Closed: [List]
- Gaps Created: [List]
- No Impact: [List]

### SSP Updates Required
- [ ] Section X.X: [Update description]
- [ ] Appendix Y: [Update description]

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
| Tags | Pass/Fail | |

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
- [ ] Control Implementation Comments

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

- [ ] All security findings addressed
- [ ] Compliance controls properly implemented
- [ ] Architecture patterns followed
- [ ] Documentation updated
- [ ] CI/CD checks passing

**Reviewer Notes:**
[Any additional context or considerations]
```
