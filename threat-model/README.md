# Threat Model Agent for Kiro CLI

A STRIDE-based threat-modeling agent that analyzes codebases by combining architectural analysis with SAST/SCA findings from the `secreview` subagent. Produces both Markdown and standalone HTML reports with Mermaid diagrams.

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed and configured
- The `secreview` agent installed (used as a subagent for SAST/SCA scanning)

## Installation

### Windows (PowerShell)

```powershell
.\install.ps1
```

### Linux / macOS (Bash)

```bash
chmod +x install.sh
./install.sh
```

The installer checks for the `secreview` dependency and offers to install it if missing.

### Manual Installation

1. Copy `threat-model.json` to `~/.kiro/agents/`
2. Copy the `resources/` folder contents to `~/.kiro/agents/threat-model-resources/`

## Usage

```
/agent threat-model
```

Then point it at a codebase:

```
Threat-model the authentication service in ./src/auth
```

The agent will:

1. Scope the target and identify trust boundaries
2. Delegate SAST/SCA scanning to the `secreview` subagent
3. Map architecture and data flows (with Mermaid diagrams)
4. Build a STRIDE threat matrix cross-referencing scan findings
5. Generate reports at `reports/threat-models/<component>/threat-model.md` and `.html`

## What's Included

| File | Purpose |
|------|---------|
| `threat-model.json` | Agent configuration (tools, permissions, resources) |
| `resources/prompt.md` | System prompt defining agent behavior |
| `resources/stride-reference.md` | STRIDE category reference with severity heuristics |
| `resources/threat-model-report.md.template` | Markdown report template |
| `resources/threat-model-report.html.template` | Dark-themed HTML report template with Mermaid |

## Uninstalling

**Windows:**
```powershell
Remove-Item "$env:USERPROFILE\.kiro\agents\threat-model.json"
Remove-Item -Recurse "$env:USERPROFILE\.kiro\agents\threat-model-resources"
```

**Linux/macOS:**
```bash
rm ~/.kiro/agents/threat-model.json
rm -rf ~/.kiro/agents/threat-model-resources
```
