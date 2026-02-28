# Compliance Workflow Multi-Agent System

**Multi-Cloud, Multi-Framework Agentic Compliance Automation**

## Executive Summary

This document defines a comprehensive multi-agent workflow system using Claude Code to help security engineers build and maintain compliant cloud infrastructure Terraform codebases. The system provides specialized perspectives for compliance, architecture, security, project management, and documentation through dedicated Claude Code skills.

**Supported Frameworks:**
- FedRAMP (Low/Moderate/High) - NIST 800-53 Rev 5
- GovRAMP (Low/Moderate/High) - NIST 800-53 Rev 5
- CMMC (Level 1/2/3) - NIST 800-171

**Supported Cloud Providers:**
- Azure (azurerm provider)
- AWS (aws provider)
- GCP (google provider)

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Session Configuration](#session-configuration)
3. [Agent Definitions](#agent-definitions)
4. [Key Workflows](#key-workflows)
5. [Implementation Guide](#implementation-guide)
6. [Control Reference](#control-reference)
7. [Usage Examples](#usage-examples)

---

## System Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              Compliance Workflow Multi-Agent System                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────┐                                                          │
│   │    /init     │  ◄── Start here: Configure cloud + framework             │
│   │              │                                                          │
│   │   Session    │      Creates: /.claude/session-context.md                │
│   │   Config     │                                                          │
│   └──────┬───────┘                                                          │
│          │                                                                  │
│          ▼                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     /pm      │  │ /compliance  │  │  /architect  │  │  /security   │    │
│  │              │  │              │  │              │  │              │    │
│  │   Project    │  │  Compliance  │  │  Terraform   │  │   Security   │    │
│  │   Manager    │  │    Expert    │  │  Architect   │  │   Reviewer   │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │            │
│         └─────────────────┴─────────────────┴─────────────────┘            │
│                                   │                                         │
│                     ┌─────────────┴─────────────┐                          │
│                     │                           │                          │
│              ┌──────┴──────┐             ┌──────┴──────┐                   │
│              │    /docs    │             │    /cicd    │                   │
│              │             │             │             │                   │
│              │Documentation│             │   CI/CD     │                   │
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

**All agents read the session context** from `/.claude/session-context.md` to adapt their behavior to the configured cloud provider and compliance framework.

---

## Session Configuration

### The `/init` Command

Every engagement starts with `/init` to configure the session:

```
User: /init

Agent: I'll help you configure this compliance session.
       [Prompts for cloud provider, framework, and level]

Result: Creates /.claude/session-context.md
```

### Session Context File

```markdown
# Session Context (Auto-generated by /init)

## Engagement Configuration
- **Cloud Provider:** Azure
- **Compliance Framework:** FedRAMP
- **Baseline Level:** Moderate
- **Control/Practice Count:** 325

## Quick Reference
[Framework-specific control families and cloud-specific patterns]
```

### Data Files

Agents reference these data files based on session configuration:

| Type | Location | Purpose |
|------|----------|---------|
| Framework | `/.claude/data/frameworks/{framework}.yaml` | Control counts, phases, families |
| Cloud | `/.claude/data/clouds/{cloud}.yaml` | Provider patterns, services, auth |
| Examples | `/examples/{cloud}/` | Terraform code patterns |

---

## Agent Definitions

### 1. Session Configuration Agent (`/init`)

**Purpose:** Configure cloud provider and compliance framework for the session

**Responsibilities:**
- Prompt for cloud provider selection (Azure, AWS, GCP)
- Prompt for compliance framework (FedRAMP, GovRAMP, CMMC)
- Prompt for baseline level
- Create session context file
- Display configuration summary

---

### 2. Project Manager Agent (`/pm`)

**Purpose:** SOW analysis, scope tracking, deliverable management

**Persona:**
> You are a senior project manager specializing in compliance authorization projects. You understand compliance timelines, assessment processes, and authorization phases. Your expertise adapts based on the configured framework (FedRAMP 3PAO engagement, GovRAMP sponsoring agency processes, or CMMC C3PAO assessment).

**Responsibilities:**
- Parse and analyze Statement of Work (SOW) documents
- Track project milestones against authorization phases
- Answer scope and deliverable questions
- Coordinate handoffs between compliance phases
- Maintain project status and risk identification

**Authorization Phases:**

| FedRAMP/GovRAMP | CMMC |
|-----------------|------|
| Preparation | Gap Assessment |
| Readiness Assessment | Remediation |
| Full Security Assessment | Assessment (Self/C3PAO) |
| Authorization | Certification |
| Continuous Monitoring | Annual Affirmation |

---

### 3. Compliance Agent (`/compliance`)

**Purpose:** Control mapping, gap analysis, SSP alignment

**Persona:**
> You are a compliance expert with deep knowledge of security frameworks. Your expertise adapts: for FedRAMP/GovRAMP you use NIST 800-53 Rev 5 controls; for CMMC you use NIST 800-171 practices. You map infrastructure implementations to specific controls and identify compliance gaps.

**Responsibilities:**
- Review Terraform code against configured framework controls
- Map infrastructure changes to specific control implementations
- Identify compliance gaps in new/modified code
- Maintain System Security Plan (SSP) alignment
- Validate inherited controls from cloud provider

**Framework-Specific Guidance:**

| Framework | Standard | Control Focus |
|-----------|----------|---------------|
| FedRAMP | NIST 800-53 Rev 5 | Low: 156, Mod: 325, High: 421 controls |
| GovRAMP | NIST 800-53 Rev 5 | Low: 125, Mod: 319, High: 410 controls |
| CMMC | NIST 800-171 | L1: 17, L2: 110, L3: 134 practices |

---

### 4. Terraform Architect Agent (`/architect`)

**Purpose:** Module design, reusability patterns, cloud best practices

**Persona:**
> You are a senior Terraform architect specializing in compliant infrastructure. You design modular, reusable Terraform code that can be adapted for multiple clients. Your expertise adapts based on the configured cloud provider (Azure Landing Zone, AWS Well-Architected, or GCP Foundation patterns).

**Responsibilities:**
- Ensure modules follow established patterns for the configured cloud
- Review variable/output conventions
- Validate module composability for multi-client reuse
- Guide state management practices
- Enforce naming conventions and compliance tags/labels

**Cloud-Specific Patterns:**

| Aspect | Azure | AWS | GCP |
|--------|-------|-----|-----|
| Provider | azurerm | aws | google |
| Region var | location | region | region |
| Grouping | resource_group_name | tags | project_id |
| Metadata | tags | tags | labels (lowercase) |
| Secrets | Key Vault | Secrets Manager | Secret Manager |
| Logging | Log Analytics | CloudWatch | Cloud Logging |

---

### 5. Security Reviewer Agent (`/security`)

**Purpose:** Security vulnerability identification, secure configuration

**Persona:**
> You are a senior security engineer specializing in cloud security. You identify vulnerabilities, validate security configurations, and ensure defense-in-depth patterns. Your expertise adapts based on the configured cloud (Azure CIS Benchmark, AWS Foundational Security, GCP Security Baselines).

**Responsibilities:**
- Review code for security vulnerabilities
- Validate encryption at rest and in transit
- Check for private connectivity vs public access
- Validate network rules and isolation
- Check for exposed secrets or sensitive data
- Review logging and monitoring configurations

**Security Checklist (All Clouds):**
- [ ] No hardcoded secrets
- [ ] Encryption at rest (CMK/KMS/CMEK)
- [ ] TLS 1.2+ enforced
- [ ] Public access disabled
- [ ] Audit logging configured
- [ ] Least privilege IAM/RBAC
- [ ] Private connectivity enabled

---

### 6. Documentation Agent (`/docs`)

**Purpose:** Compliance documentation maintenance, SSP updates

**Persona:**
> You are a technical writer specializing in compliance documentation. You understand SSP structure, policy document requirements, and evidence collection. Your expertise adapts: FedRAMP/GovRAMP use NIST 800-53 SSP structure; CMMC uses NIST 800-171 SSP with CUI boundary focus.

**Responsibilities:**
- Keep SSP aligned with infrastructure changes
- Update control implementation documentation
- Maintain module README files with control mappings
- Generate compliance evidence documentation
- Update network diagrams and architecture docs

**SSP Structures:**

| FedRAMP/GovRAMP | CMMC |
|-----------------|------|
| Section 13.X (Control Families) | Section 3.X (Security Requirements) |
| FIPS 199 Categorization | CUI Boundary Description |
| Appendix A (Network Diagram) | Appendix A (Network Topology) |
| Appendix C (Ports/Protocols) | Appendix C (Asset Inventory) |

---

### 7. CI/CD Operations Agent (`/cicd`)

**Purpose:** Pipeline management, deployment operations

**Persona:**
> You are a DevOps engineer specializing in secure CI/CD pipelines for infrastructure deployments. You understand GitHub Actions, OIDC authentication for multiple cloud providers, Terraform workflows, and deployment best practices.

**Responsibilities:**
- Review and optimize GitHub Actions workflows
- Troubleshoot deployment failures
- Validate OIDC configuration for secretless auth
- Manage environment promotions
- Ensure pipeline security

**OIDC Authentication by Cloud:**

| Cloud | Login Action | Key Parameters |
|-------|--------------|----------------|
| Azure | azure/login@v2 | client-id, tenant-id, subscription-id |
| AWS | aws-actions/configure-aws-credentials@v4 | role-to-assume, aws-region |
| GCP | google-github-actions/auth@v2 | workload_identity_provider, service_account |

---

## Key Workflows

### 1. New Module Creation Workflow (`/new-module`)

```
User: "Create a secrets management module"
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Read Session Context                                                 │
│ Cloud: [Azure/AWS/GCP] → Use appropriate provider patterns          │
│ Framework: [FedRAMP/GovRAMP/CMMC] → Use appropriate controls        │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: Architecture Design                                          │
│ - Design module interface (variables, outputs)                       │
│ - Use cloud-specific patterns from /examples/{cloud}/               │
│ - Ensure multi-client reusability                                    │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: Compliance Implementation                                    │
│ - Map to framework controls (NIST 800-53 or 800-171)                │
│ - Add compliance tags/labels                                         │
│ - Add control implementation comments                                │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: Security Hardening                                           │
│ - Validate encryption configuration                                  │
│ - Check private connectivity setup                                   │
│ - Review access control settings                                     │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 4: Documentation                                                │
│ - Create module README with usage examples                           │
│ - Document control implementations                                   │
│ - Identify SSP sections to update                                    │
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
│                    Read Session Context                              │
│     Cloud: [Azure/AWS/GCP] | Framework: [FedRAMP/GovRAMP/CMMC]      │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   /security   │       │  /compliance  │       │  /architect   │
│               │       │               │       │               │
│ - Cloud-      │       │ - Framework-  │       │ - Cloud-      │
│   specific    │       │   specific    │       │   specific    │
│   checks      │       │   controls    │       │   patterns    │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Consolidated Review Report                        │
│                                                                      │
│   Session Context: [Cloud] + [Framework] [Level]                    │
│                                                                      │
│   ## Security Findings (cloud-specific)                             │
│   ## Compliance Impact (framework-specific)                         │
│   ## Architecture Review (cloud-specific)                           │
│   ## Documentation Updates                                           │
│                                                                      │
│   Verdict: [Approve / Request Changes]                              │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. SOW Analysis Workflow (`/pm`)

```
┌─────────────────────────────────────────────────────────────────────┐
│              User provides SOW document                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Read Session Context                                                 │
│ Framework: [FedRAMP/GovRAMP/CMMC] → Use appropriate phases          │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Parse SOW                                                            │
│ - Scope of work and boundaries                                       │
│ - Deliverables and acceptance criteria                               │
│ - Resource requirements                                              │
│ - Assumptions and constraints                                        │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Map to Framework Phases                                              │
│                                                                      │
│ FedRAMP/GovRAMP:                 CMMC:                              │
│ - Preparation                    - Gap Assessment                    │
│ - Readiness Assessment           - Remediation                       │
│ - Full Security Assessment       - Assessment                        │
│ - Authorization                  - Certification                     │
│ - Continuous Monitoring          - Annual Affirmation                │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Project Brief Output                          │
│                                                                      │
│   Session Context: [Cloud] + [Framework] [Level]                    │
│   Control/Practice Count: [Number]                                  │
│                                                                      │
│   ## Executive Summary                                               │
│   ## Scope Analysis                                                  │
│   ## Deliverables Mapping                                            │
│   ## Risk Assessment                                                 │
│   ## Recommended Phases                                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Guide

### Directory Structure

```
compliance-workflow/
├── CLAUDE.md                              # Main project configuration
├── agentic-plan.md                        # This document
├── README.md                              # Repository documentation
├── .claude/
│   ├── skills/                            # Agent skill definitions
│   │   ├── init.md                        # Session Configuration
│   │   ├── pm.md                          # Project Manager
│   │   ├── compliance.md                  # Compliance Expert
│   │   ├── architect.md                   # Terraform Architect
│   │   ├── security.md                    # Security Reviewer
│   │   ├── docs.md                        # Documentation
│   │   ├── cicd.md                        # CI/CD Operations
│   │   ├── review-pr.md                   # Compound: PR Review
│   │   └── new-module.md                  # Compound: New Module
│   ├── data/
│   │   ├── frameworks/                    # Framework configuration
│   │   │   ├── fedramp.yaml
│   │   │   ├── govramp.yaml
│   │   │   └── cmmc.yaml
│   │   └── clouds/                        # Cloud provider configuration
│   │       ├── azure.yaml
│   │       ├── aws.yaml
│   │       └── gcp.yaml
│   └── session-context.md                 # Current session (created by /init)
├── examples/
│   ├── azure/                             # Azure Terraform patterns
│   │   ├── encryption.tf
│   │   ├── logging.tf
│   │   ├── network-isolation.tf
│   │   └── cicd-auth.yaml
│   ├── aws/                               # AWS Terraform patterns
│   │   ├── encryption.tf
│   │   ├── logging.tf
│   │   ├── network-isolation.tf
│   │   └── cicd-auth.yaml
│   └── gcp/                               # GCP Terraform patterns
│       ├── encryption.tf
│       ├── logging.tf
│       ├── network-isolation.tf
│       └── cicd-auth.yaml
└── docs/
    └── sow/                               # SOW documents directory
```

### Skill File Format

Each skill file follows this structure:

```markdown
---
name: skill-name
description: Brief description for Claude Code
---

## Role and Persona

[Detailed persona description - adapts to session context]

## Required Context

**CRITICAL: Before responding, you MUST read the session context:**

1. Read `/.claude/session-context.md` - Current engagement configuration
2. Read appropriate framework data file
3. Read appropriate cloud data file

If no session context exists, inform the user to run `/init` first.

## Responsibilities

[List of responsibilities]

## Instructions

[Step-by-step instructions for the agent]

## Output Format

[Expected output structure]
```

---

## Control Reference

### NIST 800-53 Rev 5 (FedRAMP/GovRAMP)

| ID | Family | Primary Agent |
|----|--------|---------------|
| AC | Access Control | /compliance, /security |
| AU | Audit and Accountability | /compliance, /cicd |
| AT | Awareness and Training | /compliance, /docs |
| CA | Assessment, Authorization, Monitoring | /compliance, /pm |
| CM | Configuration Management | /architect, /compliance |
| CP | Contingency Planning | /compliance, /docs |
| IA | Identification and Authentication | /security, /compliance |
| IR | Incident Response | /security, /compliance |
| MA | Maintenance | /compliance |
| MP | Media Protection | /security, /compliance |
| PE | Physical and Environmental | /compliance (inherited) |
| PL | Planning | /pm, /docs |
| PS | Personnel Security | /compliance, /pm |
| RA | Risk Assessment | /security, /compliance |
| SA | System and Services Acquisition | /compliance |
| SC | System and Communications Protection | /security, /architect |
| SI | System and Information Integrity | /security, /compliance |

### NIST 800-171 (CMMC)

| ID | Domain | Primary Agent |
|----|--------|---------------|
| 3.1 | Access Control | /compliance, /security |
| 3.2 | Awareness and Training | /compliance, /docs |
| 3.3 | Audit and Accountability | /compliance, /cicd |
| 3.4 | Configuration Management | /architect, /compliance |
| 3.5 | Identification and Authentication | /security, /compliance |
| 3.6 | Incident Response | /security, /compliance |
| 3.7 | Maintenance | /compliance |
| 3.8 | Media Protection | /security, /compliance |
| 3.9 | Personnel Security | /compliance, /pm |
| 3.10 | Physical Protection | /compliance (inherited) |
| 3.11 | Risk Assessment | /security, /compliance |
| 3.12 | Security Assessment | /compliance, /pm |
| 3.13 | System and Communications Protection | /security, /architect |
| 3.14 | System and Information Integrity | /security, /compliance |

---

## Usage Examples

### Example 1: Starting a New Engagement

```
User: /init

Agent: I'll help you configure this compliance session.

       Cloud Provider?
       > Azure

       Compliance Framework?
       > FedRAMP

       Baseline Level?
       > Moderate

       Session configured:
       - Cloud: Azure (azurerm)
       - Framework: FedRAMP Moderate
       - Controls: 325
```

### Example 2: Creating a Module (Azure + FedRAMP)

```
User: /new-module I need to add Azure Cosmos DB to our infrastructure

Agent: [Reads session context: Azure + FedRAMP Moderate]

       Creating FedRAMP-compliant Azure Cosmos DB module...

       - Using azurerm_cosmosdb_account resource
       - Implementing SC-8 (TLS 1.2), SC-28 (encryption)
       - Adding azurerm_monitor_diagnostic_setting for AU-2/AU-12
       - Configuring private endpoint for SC-7/AC-4
       - Applying FedRAMP compliance tags
```

### Example 3: Creating a Module (AWS + CMMC)

```
User: /new-module I need to add DynamoDB to our infrastructure

Agent: [Reads session context: AWS + CMMC Level 2]

       Creating CMMC L2-compliant AWS DynamoDB module...

       - Using aws_dynamodb_table resource
       - Implementing 3.13.8 (TLS 1.2), 3.13.16 (KMS encryption)
       - Adding aws_cloudwatch_log_group for 3.3.1/3.3.2
       - Configuring VPC endpoint for 3.13.1/3.1.3
       - Applying CMMC compliance tags
```

### Example 4: PR Review (GCP + GovRAMP)

```
User: /review-pr Review PR #42 which adds the Cloud SQL module

Agent: [Reads session context: GCP + GovRAMP High]

       ## PR Review: #42 - Cloud SQL Module

       Session Context: GCP + GovRAMP High (410 controls)

       ## Security Findings
       - google_sql_database_instance has public IP enabled ❌

       ## Compliance Impact
       - SC-7 (Boundary Protection): FAIL - requires private IP

       ## Architecture Review
       - Labels are lowercase: ✓
       - project_id variable present: ✓

       Verdict: Request Changes
```

### Example 5: SOW Analysis

```
User: /pm Analyze the attached SOW for a CMMC Level 2 project

Agent: [Reads session context: confirms CMMC Level 2]

       ## SOW Analysis

       Session Context: CMMC Level 2 (110 practices)

       ### Scope Analysis
       - In Scope: CUI boundary definition, SSP creation, technical controls
       - Out of Scope: C3PAO assessment (client responsibility)

       ### Practice Coverage
       This SOW addresses 85/110 practices across:
       - Access Control (3.1): 15 practices
       - System Protection (3.13): 12 practices
       - Audit (3.3): 9 practices

       ### Recommended Phases
       1. Gap Assessment
       2. Remediation
       3. Self-Assessment Preparation
```

---

## Appendix: Resources

### FedRAMP
- [FedRAMP Official Website](https://www.fedramp.gov/)
- [FedRAMP Authorization Boundary Guidance](https://www.fedramp.gov/assets/resources/documents/FedRAMP_Authorization_Boundary_Guidance.pdf)

### GovRAMP
- [GovRAMP Official Website](https://govramp.org/)
- [GovRAMP Rev. 5 Templates](https://govramp.org/rev-5-templates-and-resources/)

### CMMC
- [CMMC Official Website](https://dodcio.defense.gov/CMMC/)
- [NIST SP 800-171 Rev. 2](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)

### General
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-25 | Claude Code | Initial agent system design |
| 2.0 | 2026-02-27 | Claude Code | Multi-cloud, multi-framework refactor |
