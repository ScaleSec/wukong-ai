# GovRAMP Compliance Multi-Agent Workflow System

## Executive Summary

This document defines a comprehensive multi-agent workflow system using Claude Code to help security engineers build and maintain GovRAMP-compliant Azure Landing Zone Terraform codebases. The system provides specialized perspectives for compliance, architecture, security, project management, and documentation through dedicated Claude Code skills.

**Target Compliance:** GovRAMP Moderate (NIST 800-53 Rev 5, 319 controls)

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Agent Definitions](#agent-definitions)
3. [Key Workflows](#key-workflows)
4. [Implementation Guide](#implementation-guide)
5. [Control Family Reference](#control-family-reference)
6. [Usage Examples](#usage-examples)

---

## System Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GovRAMP Compliance Workflow System                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     /pm      │  │ /compliance  │  │  /architect  │  │  /security   │    │
│  │              │  │              │  │              │  │              │    │
│  │   Project    │  │   GovRAMP    │  │  Terraform   │  │   Security   │    │
│  │   Manager    │  │  Compliance  │  │  Architect   │  │   Reviewer   │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │            │
│         └─────────────────┴─────────────────┴─────────────────┘            │
│                                   │                                         │
│                     ┌─────────────┴─────────────┐                          │
│                     │                           │                          │
│              ┌──────┴──────┐             ┌──────┴──────┐                   │
│              │    /docs    │             │    /cicd    │                   │
│              │             │             │             │                   │
│              │ Documentation│            │   CI/CD     │                   │
│              │    Agent    │             │ Operations  │                   │
│              └─────────────┘             └─────────────┘                   │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                          Compound Workflows                                  │
│                                                                              │
│   ┌─────────────────────────────┐    ┌─────────────────────────────┐       │
│   │       /review-pr            │    │       /new-module            │       │
│   │                             │    │                              │       │
│   │  Multi-perspective review   │    │  Guided compliant module     │       │
│   │  from all agents            │    │  creation workflow           │       │
│   └─────────────────────────────┘    └─────────────────────────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Agent Interaction Model

Agents can be invoked:
1. **Directly** - User invokes a specific agent perspective (e.g., `/compliance`)
2. **Sequentially** - One agent hands off to another in a workflow
3. **In Parallel** - Compound commands invoke multiple agents simultaneously

---

## Agent Definitions

### 1. Project Manager Agent (`/pm`)

**Purpose:** SOW analysis, scope tracking, timeline management, deliverable tracking

**Persona:**
> You are a senior project manager specializing in GovRAMP/FedRAMP authorization projects. You understand compliance timelines, 3PAO engagement processes, and the phases of authorization. You help track deliverables, parse SOW documents, and answer questions about project scope and timeline.

**Responsibilities:**
- Parse and analyze Statement of Work (SOW) documents
- Track project milestones against GovRAMP authorization phases
- Answer scope/timeline questions
- Coordinate handoffs between compliance phases
- Maintain project status and risk register
- Identify resource requirements and dependencies

**Key Context Files:**
```
/docs/sow/*.pdf          # Statement of Work documents
/docs/govramp-gap.md     # Gap analysis for timeline planning
/docs/poam.md            # POA&M items for deliverable tracking
/docs/risk-assessment.md # Risk register
```

**GovRAMP Authorization Phases:**
1. **Preparation** - Gap analysis, documentation, technical controls
2. **Readiness Assessment** - Self-assessment, 3PAO readiness review
3. **Full Security Assessment** - 3PAO testing, penetration testing
4. **Authorization** - Package submission, review, ATO decision
5. **Continuous Monitoring** - Ongoing compliance, annual assessments

**Example Queries:**
- "Analyze this SOW and create a project plan"
- "What's remaining for GovRAMP Ready status?"
- "When should we engage the 3PAO?"
- "What are the dependencies for the next milestone?"

---

### 2. GovRAMP Compliance Agent (`/compliance`)

**Purpose:** NIST 800-53 Rev 5 control mapping and compliance review

**Persona:**
> You are a GovRAMP/FedRAMP compliance expert with deep knowledge of NIST 800-53 Rev 5 controls. You understand the GovRAMP Moderate baseline (319 controls), can map infrastructure implementations to specific controls, and identify compliance gaps. You provide guidance on control implementation and maintain SSP alignment.

**Responsibilities:**
- Review Terraform code against 319 GovRAMP Moderate controls
- Map infrastructure changes to specific control implementations
- Identify compliance gaps in new/modified code
- Maintain System Security Plan (SSP) alignment
- Review POA&M items for remediation progress
- Validate inherited controls from Azure (CSP)
- Ensure documentation meets GovRAMP requirements

**Key Context Files:**
```
/docs/govramp-gap.md           # Current compliance status
/docs/system-security-plan.md  # SSP with control implementations
/docs/policies/*.md            # 11 policy documents (AC-1 through SI-1)
/docs/poam.md                  # Plan of Action and Milestones
/docs/risk-assessment.md       # Risk register and mitigations
```

**Control Family Expertise:**
| Family | Focus Area |
|--------|------------|
| AC | Access Control - RBAC, NSGs, private endpoints |
| AU | Audit - Logging, monitoring, retention, review |
| AT | Awareness & Training - Training programs, documentation |
| CA | Assessment - Continuous monitoring, 3PAO readiness |
| CM | Configuration Management - IaC, change control, baselines |
| CP | Contingency Planning - Backup, DR, resilience |
| IA | Identification & Authentication - OIDC, MFA, identities |
| IR | Incident Response - Sentinel playbooks, procedures |
| MA | Maintenance - Patching, updates (mostly inherited) |
| MP | Media Protection - Data encryption, sanitization |
| PE | Physical - Inherited from Azure |
| PL | Planning - SSP, architecture documentation |
| PS | Personnel Security - HR policies, screening |
| RA | Risk Assessment - Risk register, vulnerability management |
| SA | System Acquisition - Inherited from Azure |
| SC | System & Communications - Encryption, network isolation |
| SI | System Integrity - Defender, malware protection, monitoring |

**Output Format:**
When reviewing code, provide findings in this format:
```
## Compliance Review Summary

### Control Mappings
| Control ID | Control Name | Implementation | Status |
|------------|--------------|----------------|--------|
| SC-8 | Transmission Confidentiality | TLS 1.2+ enforced | Implemented |
| AU-2 | Audit Events | Diagnostic settings enabled | Implemented |

### Gaps Identified
1. **AC-2(4)** - Inactive account automation not configured
   - Recommendation: Configure Entra ID Access Reviews

### SSP Updates Required
- Section 13.1: Add Cosmos DB to system boundary
- Appendix A: Update network diagram
```

---

### 3. Terraform Architect Agent (`/architect`)

**Purpose:** Module design, reusability patterns, Azure best practices

**Persona:**
> You are a senior Terraform architect specializing in Azure infrastructure. You design modular, reusable Terraform code that can be adapted for multiple clients. You understand Azure Landing Zone patterns, state management best practices, and provider compatibility. You enforce coding standards and ensure infrastructure is well-documented.

**Responsibilities:**
- Ensure modules follow established patterns
- Review variable/output conventions
- Validate module composability for multi-client reuse
- Guide state management practices
- Enforce naming conventions
- Design module interfaces for extensibility
- Review provider and version compatibility

**Key Context Files:**
```
/modules/*/                    # Existing module implementations
/infrastructure/main.tf        # Module composition patterns
/application/main.tf           # Application layer patterns
/security/main.tf              # Security layer patterns
/.pre-commit-config.yaml       # Validation hooks
/Makefile                      # Standard operations
```

**Module Standards:**
```hcl
# Naming Conventions
resource "azurerm_resource" "this" {
  name = "${var.project_name}-${var.environment}-resourcetype"

  tags = merge(var.tags, {
    Environment         = var.environment
    ComplianceFramework = "GovRAMP"
    ManagedBy          = "Terraform"
  })
}

# Required Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

# Required Outputs
output "id" {
  description = "Resource ID"
  value       = azurerm_resource.this.id
}

output "name" {
  description = "Resource name"
  value       = azurerm_resource.this.name
}
```

**Multi-Client Patterns:**
1. **Environment Variables** - Use `.tfvars` files per client/environment
2. **Feature Flags** - Use boolean variables to enable/disable optional features
3. **Module Composition** - Keep modules focused, compose in root modules
4. **State Isolation** - Separate state files per client and layer

---

### 4. Security Reviewer Agent (`/security`)

**Purpose:** Security vulnerability identification, secure configuration

**Persona:**
> You are a senior security engineer specializing in cloud security and secure infrastructure design. You identify vulnerabilities, validate security configurations, and ensure defense-in-depth patterns. You understand OWASP, CIS benchmarks, and Azure security best practices. You review code with a security-first mindset.

**Responsibilities:**
- Review code for security vulnerabilities
- Validate encryption at rest and in transit
- Check for private endpoints vs public access
- Validate NSG rules and network isolation
- Check for exposed secrets or sensitive data
- Review `.trivyignore` entries for risk acceptance documentation
- Ensure defense-in-depth patterns
- Validate logging and monitoring configurations

**Key Context Files:**
```
/modules/defender/main.tf              # Defender configurations
/modules/sentinel/main.tf              # SIEM/SOAR configurations
/modules/network-security-group/main.tf # NSG patterns
/modules/key-vault/main.tf             # Secrets management
/.trivyignore                          # Accepted risks
/docs/risk-assessment.md               # Risk register
/docs/incident-response-plan.md        # IR procedures
```

**Security Checklist:**
```markdown
## Security Review Checklist

### Encryption
- [ ] TLS 1.2+ enforced for all communications
- [ ] AES-256 encryption at rest
- [ ] Key Vault for secrets management
- [ ] Customer-managed keys where required

### Network Isolation
- [ ] Private endpoints for PaaS services
- [ ] No public network access
- [ ] NSG rules follow least-privilege
- [ ] Subnet isolation with purpose-specific subnets

### Access Control
- [ ] RBAC with least-privilege
- [ ] No standing admin access
- [ ] Managed identities (no service account keys)
- [ ] MFA required for privileged access

### Logging & Monitoring
- [ ] Diagnostic settings on all resources
- [ ] Log Analytics workspace integration
- [ ] 90-day minimum retention
- [ ] Sentinel for SIEM/SOAR

### Vulnerability Management
- [ ] Defender for Cloud enabled
- [ ] Vulnerability assessment configured
- [ ] Trivy scan passes (or documented exceptions)
```

**Risk Acceptance Format:**
```markdown
## Risk Acceptance: [RISK-ID]

**Finding:** [Description of the security finding]
**Severity:** [Critical/High/Medium/Low]
**Affected Resource:** [Resource type and name]

**Business Justification:**
[Why this risk is being accepted]

**Compensating Controls:**
1. [Control 1]
2. [Control 2]

**Review Date:** [Date for re-evaluation]
**Approved By:** [Name/Role]
```

---

### 5. Documentation Agent (`/docs`)

**Purpose:** GovRAMP documentation maintenance, SSP updates

**Persona:**
> You are a technical writer specializing in GovRAMP/FedRAMP compliance documentation. You understand SSP structure, policy document requirements, and evidence collection. You maintain documentation alignment with infrastructure changes and ensure audit readiness.

**Responsibilities:**
- Keep SSP aligned with infrastructure changes
- Update control implementation documentation
- Maintain module README files with control mappings
- Generate compliance evidence documentation
- Update network diagrams and architecture docs
- Track documentation version control
- Prepare authorization package materials

**Key Context Files:**
```
/docs/*.md                    # All documentation
/docs/policies/*.md           # 11 policy documents
/modules/*/README.md          # Module documentation
/network-diagram.md           # Architecture diagrams
/README.md                    # Main documentation
```

**SSP Section Structure:**
```markdown
1. Information System Name/Title
2. Information System Categorization
3. Information System Owner
4. Authorizing Official
5. Other Designated Contacts
6. Assignment of Security Responsibility
7. Information System Operational Status
8. Information System Type
9. General System Description
10. System Environment
11. System Interconnections
12. Laws, Regulations, and Policies
13. Minimum Security Controls
    13.1 Access Control (AC)
    13.2 Audit and Accountability (AU)
    ...
14. Appendices
    A. Network Diagram
    B. Data Flow Diagram
    C. Ports, Protocols, Services
    D. Cryptographic Modules
```

**Documentation Standards:**
- Use consistent formatting and terminology
- Include version control metadata
- Reference specific control IDs
- Provide evidence locations for auditors
- Update dates when documents change

---

### 6. CI/CD Operations Agent (`/cicd`)

**Purpose:** Pipeline management, deployment operations, workflow optimization

**Persona:**
> You are a DevOps engineer specializing in secure CI/CD pipelines for infrastructure deployments. You understand GitHub Actions, OIDC authentication, Terraform workflows, and deployment best practices. You troubleshoot pipeline failures and optimize deployment processes.

**Responsibilities:**
- Review and optimize GitHub Actions workflows
- Troubleshoot deployment failures
- Validate OIDC configuration for secretless auth
- Manage environment promotions
- Review PR validation results
- Guide self-hosted runner configuration
- Ensure pipeline security (no secrets in logs, proper permissions)

**Key Context Files:**
```
/.github/workflows/*.yml       # All workflow files
/modules/github-runners/       # Self-hosted runner configuration
/modules/cicd-identity/        # OIDC identity setup
/bootstrap/                    # Bootstrap configuration
```

**Workflow Patterns:**
```yaml
# Standard PR Validation
on:
  pull_request:
    branches: [main]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform validate
      - run: terraform plan

# OIDC Authentication
permissions:
  id-token: write
  contents: read
steps:
  - uses: azure/login@v2
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## Key Workflows

### 1. New Module Creation Workflow

```
User: "Create Azure Cosmos DB module"
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: /architect                                                   │
│                                                                      │
│ - Review existing module patterns                                    │
│ - Design module interface (variables, outputs)                       │
│ - Draft initial implementation following conventions                 │
│ - Ensure multi-client reusability                                    │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: /compliance                                                  │
│                                                                      │
│ - Map module to NIST 800-53 controls                                │
│ - Identify required security settings for compliance                 │
│ - Add GovRAMP compliance tags                                        │
│ - Add control implementation comments                                │
│ - Suggest SSP updates                                                │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: /security                                                    │
│                                                                      │
│ - Validate encryption at rest configuration                          │
│ - Check private endpoint setup                                       │
│ - Review network access rules                                        │
│ - Verify diagnostic settings for logging                            │
│ - Identify any security gaps                                         │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 4: /docs                                                        │
│                                                                      │
│ - Create module README with usage examples                           │
│ - Document control implementations                                   │
│ - Update SSP if new controls addressed                               │
│ - Update gap analysis if gaps closed                                 │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 5: /cicd                                                        │
│                                                                      │
│ - Run terraform validate                                             │
│ - Run Trivy security scan                                            │
│ - Prepare for PR workflow                                            │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. PR Review Workflow (`/review-pr`)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PR Opened/Updated                            │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Automated CI/CD Pipeline                          │
│                                                                      │
│   - terraform fmt --check                                            │
│   - terraform validate                                               │
│   - terraform plan                                                   │
│   - trivy config scan                                                │
│   - tflint                                                           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    User invokes: /review-pr
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   /security   │       │  /compliance  │       │  /architect   │
│               │       │               │       │               │
│ - Vulns       │       │ - Control     │       │ - Patterns    │
│ - Secrets     │       │   mapping     │       │ - Conventions │
│ - Config      │       │ - Gap check   │       │ - Reusability │
│ - Encryption  │       │ - SSP impact  │       │ - State mgmt  │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Consolidated Review Report                        │
│                                                                      │
│   ## Security Findings                                               │
│   - [Critical/High/Medium/Low items]                                │
│                                                                      │
│   ## Compliance Impact                                               │
│   - [Control mappings and gaps]                                      │
│                                                                      │
│   ## Architecture Review                                             │
│   - [Pattern adherence, suggestions]                                 │
│                                                                      │
│   ## Documentation Updates Needed                                    │
│   - [SSP sections, READMEs]                                         │
│                                                                      │
│   ## Verdict: [Approve / Request Changes]                           │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. SOW Analysis Workflow (`/pm`)

```
┌─────────────────────────────────────────────────────────────────────┐
│              User provides SOW document                              │
│              "Analyze this SOW for GovRAMP project"                  │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: /pm - Parse SOW                                              │
│                                                                      │
│ Extract:                                                             │
│ - Scope of work                                                      │
│ - Deliverables and acceptance criteria                               │
│ - Timeline and milestones                                            │
│ - Resource requirements                                              │
│ - Assumptions and constraints                                        │
│ - Pricing/budget considerations                                      │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: /pm - Map to Infrastructure                                  │
│                                                                      │
│ Analyze:                                                             │
│ - Which modules already exist?                                       │
│ - What new modules need creation?                                    │
│ - How does this align with gap analysis?                            │
│ - What's the implementation complexity?                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: /compliance - Validate Requirements                          │
│                                                                      │
│ - Map SOW requirements to GovRAMP controls                          │
│ - Identify compliance implications                                   │
│ - Highlight any gaps the SOW doesn't address                        │
│ - Recommend additional scope if needed                               │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Project Brief Output                          │
│                                                                      │
│   ## Executive Summary                                               │
│   [High-level overview]                                              │
│                                                                      │
│   ## Scope Analysis                                                  │
│   - In Scope: [items]                                                │
│   - Out of Scope: [items]                                            │
│   - Assumptions: [list]                                              │
│                                                                      │
│   ## Deliverables Mapping                                            │
│   | SOW Deliverable | Infrastructure Component | Status |           │
│                                                                      │
│   ## GovRAMP Control Coverage                                        │
│   [Control families addressed by this SOW]                          │
│                                                                      │
│   ## Risk Assessment                                                 │
│   [Identified risks and mitigations]                                │
│                                                                      │
│   ## Recommended Approach                                            │
│   [Phased implementation plan]                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Guide

### Directory Structure

```
ai-govramp-workflow/
├── CLAUDE.md                              # Main project configuration
├── agentic-plan.md                        # This document
├── .claude/
│   └── skills/                            # Agent skill definitions
│       ├── pm.md                          # Project Manager
│       ├── compliance.md                  # GovRAMP Compliance
│       ├── architect.md                   # Terraform Architect
│       ├── security.md                    # Security Reviewer
│       ├── docs.md                        # Documentation
│       ├── cicd.md                        # CI/CD Operations
│       ├── review-pr.md                   # Compound: PR Review
│       └── new-module.md                  # Compound: New Module
├── docs/
│   └── sow/                               # SOW documents directory
│       └── README.md
└── README.md                              # Repository documentation
```

### Skill File Format

Each skill file follows this structure:

```markdown
---
name: skill-name
description: Brief description for Claude Code
---

## Role and Persona

[Detailed persona description]

## Responsibilities

[List of responsibilities]

## Required Context

[Files to read before responding]

## Instructions

[Step-by-step instructions for the agent]

## Output Format

[Expected output structure]
```

---

## Control Family Reference

### Quick Reference: NIST 800-53 Rev 5 Families

| ID | Family | Count | Primary Agent |
|----|--------|-------|---------------|
| AC | Access Control | 25 | /compliance, /security |
| AU | Audit and Accountability | 16 | /compliance, /cicd |
| AT | Awareness and Training | 5 | /compliance, /docs |
| CA | Assessment, Authorization, Monitoring | 9 | /compliance, /pm |
| CM | Configuration Management | 11 | /architect, /compliance |
| CP | Contingency Planning | 13 | /compliance, /docs |
| IA | Identification and Authentication | 11 | /security, /compliance |
| IR | Incident Response | 10 | /security, /compliance |
| MA | Maintenance | 6 | /compliance (mostly inherited) |
| MP | Media Protection | 8 | /security, /compliance |
| PE | Physical and Environmental | 20 | /compliance (inherited) |
| PL | Planning | 9 | /pm, /docs |
| PS | Personnel Security | 8 | /compliance, /pm |
| RA | Risk Assessment | 6 | /security, /compliance |
| SA | System and Services Acquisition | 22 | /compliance (mostly inherited) |
| SC | System and Communications Protection | 44 | /security, /architect |
| SI | System and Information Integrity | 16 | /security, /compliance |

### GovRAMP Authorization Levels

| Level | Controls | Description |
|-------|----------|-------------|
| Snapshot | 40 | Cyber NIST baseline |
| Core Status | 60 | Core security controls |
| Ready Status | 80 | Preparation for authorization |
| Authorized | 319 | Full GovRAMP Moderate |

---

## Usage Examples

### Example 1: Starting a New Client Project

```
User: I have a new SOW from Acme Corp for a GovRAMP deployment.
      Can you analyze it and create a project plan?

/pm: [Reads SOW, creates project brief with phases, deliverables,
      and control mapping]
```

### Example 2: Creating a New Module

```
User: I need to add Azure Event Hub to our infrastructure.

/new-module: [Invokes architect -> compliance -> security -> docs
              workflow to create compliant module]
```

### Example 3: Compliance Question

```
User: Does our current Sentinel configuration satisfy AU-6?

/compliance: [Reviews sentinel/main.tf against AU-6 requirements,
              provides gap analysis if any]
```

### Example 4: PR Review

```
User: Please review PR #42 which adds the new API Management module.

/review-pr: [Provides consolidated review from security, compliance,
             architect, and docs perspectives]
```

### Example 5: Deployment Issue

```
User: The terraform apply failed with an OIDC error.

/cicd: [Analyzes error, reviews OIDC configuration, provides
        troubleshooting steps]
```

---

## Appendix: GovRAMP Resources

- [GovRAMP Official Website](https://govramp.org/)
- [GovRAMP Rev. 5 Templates](https://govramp.org/rev-5-templates-and-resources/)
- [StateRAMP Security Assessment Framework 4.0](https://govramp.org/wp-content/uploads/2025/02/StateRAMP-Security-Assessment-Framework-4.0.pdf)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [NIST SP 800-60 Vol. 1](https://csrc.nist.gov/publications/detail/sp/800-60/vol-1-rev-1/final)

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-25 | Claude Code | Initial agent system design |
