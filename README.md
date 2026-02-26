# AI GovRAMP Workflow

A multi-agent workflow system using Claude Code to help security engineers build and maintain GovRAMP-compliant Azure Landing Zone Terraform codebases.

## Overview

This repository provides specialized Claude Code agents for different aspects of GovRAMP compliance:

| Agent | Command | Purpose |
|-------|---------|---------|
| Project Manager | `/pm` | SOW analysis, scope/timeline, deliverable tracking |
| GovRAMP Compliance | `/compliance` | NIST 800-53 control mapping, gap analysis |
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
- Access to a GovRAMP infrastructure repository

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/ai-govramp-workflow.git
   ```

2. Copy the `.claude/skills/` directory to your infrastructure repository:
   ```bash
   cp -r ai-govramp-workflow/.claude/skills/ your-infra-repo/.claude/skills/
   ```

3. Copy the `CLAUDE.md` to your infrastructure repository and customize:
   ```bash
   cp ai-govramp-workflow/CLAUDE.md your-infra-repo/CLAUDE.md
   ```

4. Start Claude Code in your infrastructure repository:
   ```bash
   cd your-infra-repo
   claude
   ```

## Usage Examples

### Analyze a Statement of Work

```
/pm Please analyze the SOW in docs/sow/client-project.pdf and create a project plan
```

### Review Code for Compliance

```
/compliance Review the new cosmos-db module for GovRAMP compliance
```

### Create a New Module

```
/new-module I need to add Azure Event Hub to our infrastructure
```

### Comprehensive PR Review

```
/review-pr Review PR #42 which adds the API Management module
```

### Troubleshoot CI/CD

```
/cicd The terraform apply failed with an OIDC authentication error
```

## Target Compliance

- **Framework:** NIST 800-53 Rev 5
- **Baseline:** GovRAMP Moderate (319 controls)
- **Key Control Families:** AC, AU, CM, IA, SC, SI

## Documentation

- [Full Agent System Design](agentic-plan.md) - Comprehensive documentation of all agents and workflows
- [CLAUDE.md](CLAUDE.md) - Project configuration and quick reference

## Directory Structure

```
ai-govramp-workflow/
├── CLAUDE.md                    # Project configuration
├── agentic-plan.md              # Full agent system documentation
├── README.md                    # This file
├── .claude/
│   └── skills/                  # Agent skill definitions
│       ├── pm.md                # Project Manager
│       ├── compliance.md        # GovRAMP Compliance
│       ├── architect.md         # Terraform Architect
│       ├── security.md          # Security Reviewer
│       ├── docs.md              # Documentation
│       ├── cicd.md              # CI/CD Operations
│       ├── review-pr.md         # Compound: PR Review
│       └── new-module.md        # Compound: New Module
└── docs/
    └── sow/                     # SOW documents directory
        └── README.md
```

## GovRAMP Resources

- [GovRAMP Official Website](https://govramp.org/)
- [GovRAMP Rev. 5 Templates](https://govramp.org/rev-5-templates-and-resources/)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## License

[Your License]

## Contributing

[Contribution guidelines]
