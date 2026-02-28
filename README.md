# Compliance Workflow System

**Multi-Cloud, Multi-Framework Agentic Compliance Automation**

A multi-agent workflow system using Claude Code to help security engineers build and maintain compliant cloud infrastructure Terraform codebases.

## Supported Configurations

### Compliance Frameworks
| Framework | Standard | Levels |
|-----------|----------|--------|
| FedRAMP | NIST 800-53 Rev 5 | Low (156), Moderate (325), High (421) |
| GovRAMP | NIST 800-53 Rev 5 | Low (125), Moderate (319), High (410) |
| CMMC | NIST 800-171 | Level 1 (17), Level 2 (110), Level 3 (134) |

### Cloud Providers
| Provider | Terraform Provider | Key Features |
|----------|-------------------|--------------|
| Azure | azurerm | Private Endpoints, Log Analytics, Key Vault |
| AWS | aws | VPC Endpoints, CloudWatch, Secrets Manager |
| GCP | google | Private Service Connect, Cloud Logging, Secret Manager |

## Overview

This repository provides specialized Claude Code agents for different aspects of compliance:

| Agent | Command | Purpose |
|-------|---------|---------|
| Session Config | `/init` | Configure cloud provider and compliance framework |
| Project Manager | `/pm` | SOW analysis, scope tracking, deliverable management |
| Compliance Expert | `/compliance` | Control mapping, gap analysis, SSP alignment |
| Terraform Architect | `/architect` | Module design, patterns, conventions |
| Security Reviewer | `/security` | Vulnerability review, secure configuration |
| Documentation | `/docs` | SSP maintenance, policy updates |
| CI/CD Operations | `/cicd` | Pipeline troubleshooting, deployments |

### Compound Workflows

| Command | Purpose |
|---------|---------|
| `/review-pr` | Multi-perspective PR review from all agents |
| `/new-module` | Guided compliant Terraform module creation |

## Getting Started

### Prerequisites

- [Claude Code CLI](https://github.com/anthropics/claude-code) installed
- Access to a cloud infrastructure repository

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/compliance-workflow.git
   ```

2. Copy the required directories to your infrastructure repository:
   ```bash
   cp -r compliance-workflow/.claude/ your-infra-repo/.claude/
   cp -r compliance-workflow/examples/ your-infra-repo/examples/
   ```

3. Copy the configuration files:
   ```bash
   cp compliance-workflow/CLAUDE.md your-infra-repo/CLAUDE.md
   ```

4. Start Claude Code in your infrastructure repository:
   ```bash
   cd your-infra-repo
   claude
   ```

5. **Configure the session** (required first step):
   ```
   /init
   ```

## Usage Examples

### Configure Your Session

```
/init
```
This prompts for cloud provider, compliance framework, and baseline level.

### Create a New Module (Azure + FedRAMP)

```
/new-module I need to add Azure Cosmos DB to our infrastructure
```

### Create a New Module (AWS + CMMC)

```
/new-module I need to add DynamoDB for CUI storage
```

### Review Code for Compliance

```
/compliance Review the new secrets-manager module
```

### Comprehensive PR Review

```
/review-pr Review PR #42 which adds the API Gateway module
```

### Analyze a Statement of Work

```
/pm Analyze the SOW in docs/sow/client-project.pdf
```

### Troubleshoot CI/CD

```
/cicd The terraform apply failed with an OIDC authentication error
```

## Directory Structure

```
compliance-workflow/
├── CLAUDE.md                    # Project configuration
├── agentic-plan.md              # Full agent system documentation
├── README.md                    # This file
├── .claude/
│   ├── skills/                  # Agent skill definitions
│   │   ├── init.md              # Session Configuration
│   │   ├── pm.md                # Project Manager
│   │   ├── compliance.md        # Compliance Expert
│   │   ├── architect.md         # Terraform Architect
│   │   ├── security.md          # Security Reviewer
│   │   ├── docs.md              # Documentation
│   │   ├── cicd.md              # CI/CD Operations
│   │   ├── review-pr.md         # Compound: PR Review
│   │   └── new-module.md        # Compound: New Module
│   ├── data/
│   │   ├── frameworks/          # Framework configuration
│   │   │   ├── fedramp.yaml
│   │   │   ├── govramp.yaml
│   │   │   └── cmmc.yaml
│   │   └── clouds/              # Cloud provider configuration
│   │       ├── azure.yaml
│   │       ├── aws.yaml
│   │       └── gcp.yaml
│   └── session-context.md       # Current session (created by /init)
├── examples/
│   ├── azure/                   # Azure Terraform patterns
│   ├── aws/                     # AWS Terraform patterns
│   └── gcp/                     # GCP Terraform patterns
└── docs/
    └── sow/                     # SOW documents directory
```

## How It Works

1. **Session Configuration**: Run `/init` to select your cloud provider and compliance framework
2. **Context-Aware Agents**: All agents read the session context to provide relevant guidance
3. **Cloud-Specific Patterns**: Examples and patterns adapt to your configured cloud
4. **Framework-Specific Controls**: Compliance mapping uses the correct standard (800-53 or 800-171)

## Resources

### FedRAMP
- [FedRAMP Official Website](https://www.fedramp.gov/)
- [FedRAMP Templates](https://www.fedramp.gov/templates/)

### GovRAMP
- [GovRAMP Official Website](https://govramp.org/)
- [GovRAMP Rev. 5 Templates](https://govramp.org/rev-5-templates-and-resources/)

### CMMC
- [CMMC Official Website](https://dodcio.defense.gov/CMMC/)
- [NIST SP 800-171](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)

### General
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Documentation

- [Full Agent System Design](agentic-plan.md) - Comprehensive documentation of all agents and workflows
- [CLAUDE.md](CLAUDE.md) - Project configuration and quick reference

## License

[Your License]

## Contributing

[Contribution guidelines]
