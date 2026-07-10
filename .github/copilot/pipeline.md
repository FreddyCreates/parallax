# PARALLAX Multi-Agent Pipeline

## Pipeline Architecture

```
┌──────────────┐    Handoff    ┌──────────────┐    Handoff    ┌──────────────┐    Handoff    ┌──────────────┐    Handoff    ┌──────────────┐
│   Product    │ ──────────▶  │    UI/UX     │ ──────────▶  │  Software    │ ──────────▶  │  Security    │ ──────────▶  │   Growth     │
│   Manager    │              │  Developer   │              │  Engineer    │              │  Engineer    │              │  Marketer    │
└──────────────┘              └──────────────┘              └──────────────┘              └──────────────┘              └──────────────┘
      │                              │                              │                              │                              │
  Multimodal                    Plan Mode                   Skills (Google Cloud)            Plugins                      BigQuery MCP
                                Figma MCP                   MCP (DevDoc)                    Hooks
                                                            Subagents
```

## Agent Definitions

| # | Agent | File | Capabilities | Input | Output |
|---|-------|------|-------------|-------|--------|
| 1 | Product Manager | `product-manager.md` | Multimodal (images, text, diagrams) | Raw user requirements | Structured product brief |
| 2 | UI/UX Developer | `ui-ux-developer.md` | Plan Mode, Figma MCP | Product brief | Component specs & design tokens |
| 3 | Software Engineer | `software-engineer.md` | Skills (Google Cloud), MCP (DevDoc), Subagents | UI/UX specs | Production code + tests |
| 4 | Security Engineer | `security-engineer.md` | Plugins, Hooks | Implementation summary | Security audit & clearance |
| 5 | Growth Marketer | `growth-marketer.md` | BigQuery MCP | Security-cleared release | Analytics & growth plan |

## How It Works

### Sequential Handoff Model

Each agent completes its work and produces a structured handoff document for the next agent in the pipeline. The handoff contains all context needed for the downstream agent to do its job without backtracking.

### Triggering the Pipeline

The pipeline starts when the **Product Manager** receives a request. It can be triggered by:
- A new GitHub issue
- A user message with requirements (text, images, diagrams)
- A feature request from any stakeholder

### Handoff Format

Each handoff follows a consistent structure:
1. **Summary**: What was done in this stage
2. **Artifacts**: What was produced (specs, code, reports)
3. **Context for Next**: Specific information the next agent needs
4. **Blockers**: Any unresolved questions that need escalation

### Escalation

If any agent encounters a blocker:
- **Within scope**: Resolve and document the decision
- **Out of scope**: Escalate back to the Product Manager with context
- **Security critical**: Security Engineer can BLOCK the pipeline

## Configuration

### MCP Servers Referenced

| Agent | MCP Server | Purpose |
|-------|-----------|---------|
| UI/UX Developer | Figma MCP | Design asset extraction, token sync |
| Software Engineer | DevDoc MCP | API documentation lookup |
| Growth Marketer | BigQuery MCP | Analytics queries and dashboards |

### Plugins & Hooks

| Agent | Integration | Purpose |
|-------|------------|---------|
| Security Engineer | CodeQL | Static analysis security scanning |
| Security Engineer | Pre-commit hooks | Prevent secrets, enforce standards |
| Security Engineer | Deployment gates | Block insecure releases |

## PARALLAX-Specific Context

This pipeline operates on a multi-canister ICP organism:

- **9 substrates** organized in 3 tiers
- **Caffeine** build system for base infrastructure
- **PARALLAX Dev** toolchain for multi-substrate orchestration
- **Motoko** backend + **React/TypeScript** frontend
- **Internet Identity** for decentralized auth
