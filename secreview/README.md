# SecReview Agent for Kiro CLI

A SAST-driven security reviewer that performs static analysis and SCA on source code to identify vulnerabilities, map the attack surface, and produce targeted findings that feed into DAST/pentest workflows.

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed and configured
- Recommended: [Semgrep](https://semgrep.dev) installed for automated SAST scanning
- Recommended: Language-specific audit tools (`npm audit`, `pip-audit`, `cargo audit`)

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

The installer copies:
- Agent config to `~/.kiro/agents/secreview.json`
- Prompt to `~/.kiro/agents/secreview-resources/prompt.md`

### Manual Installation

1. Copy `secreview.json` to `~/.kiro/agents/`
2. Copy `prompt.md` to `~/.kiro/agents/secreview-resources/`

## Usage

Start a Kiro CLI chat session and switch to the agent:

```
/agent secreview
```

Then point it at code:

```
review ./src/routes/
```

or:

```
find injection sinks in this project
```

### Workflow

The agent follows a structured analysis pipeline:

1. **Discover tech stack** — frameworks, entry points, config files
2. **SCA** — identify vulnerable dependencies, check reachability
3. **Automated SAST** — run semgrep with appropriate rulesets
4. **Manual pattern hunting** — grep for vulnerability patterns scanners miss
5. **SCA-informed source analysis** — trace whether vulnerable APIs are actually called
6. **Attack surface mapping** — endpoint, parameter, sink, suggested payload
7. **Structured report** — prioritized findings with DAST payloads

### What It Finds

- SQL injection, XSS, SSRF, path traversal, command injection
- Auth/authz gaps, JWT misconfigurations
- Insecure deserialization, mass assignment, IDOR
- Hardcoded secrets, vulnerable dependencies
- Typosquatting candidates in dependency trees

## Used As a Subagent

The `bughunter` and `threat-model` agents invoke secreview as a subagent to gather SAST/SCA findings before dynamic testing or threat modeling. You can also invoke it directly from any agent:

```
subagent: secreview
prompt: "Run full SAST+SCA on ./src. Produce ranked findings and DAST payloads."
```

## Uninstalling

**Windows:**
```powershell
Remove-Item "$env:USERPROFILE\.kiro\agents\secreview.json"
Remove-Item -Recurse "$env:USERPROFILE\.kiro\agents\secreview-resources"
```

**Linux/macOS:**
```bash
rm ~/.kiro/agents/secreview.json
rm -rf ~/.kiro/agents/secreview-resources
```
