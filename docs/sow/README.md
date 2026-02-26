# Statement of Work Documents

This directory contains Statement of Work (SOW) documents for client projects.

## Usage

Place SOW documents (PDF or Markdown) in this directory. Use the `/pm` agent to analyze them:

```
/pm Analyze the SOW in docs/sow/client-project.pdf
```

## SOW Analysis Output

The Project Manager agent will provide:

1. **Executive Summary** - High-level project overview
2. **Scope Analysis** - In/out of scope items, assumptions
3. **Deliverables Mapping** - How SOW items map to infrastructure components
4. **GovRAMP Control Coverage** - Which controls are addressed
5. **Risk Assessment** - Identified risks and mitigations
6. **Recommended Phases** - Implementation approach

## File Naming Convention

```
[client-name]-[project-type]-[date].pdf
```

Examples:
- `acme-govramp-authorization-2026-02.pdf`
- `globex-landing-zone-2026-03.pdf`
