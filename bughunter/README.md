# BugHunter Agent for Kiro CLI

A bug-hunting and external red-team operator agent with 51 skills, 14 workflow commands, and 681 disclosed-report patterns across 24 vulnerability classes. Auto-loads relevant skills by keyword.

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed and configured
- The `secreview` agent installed (used as a subagent for SAST/SCA when source is available)
- Optional: Burp Suite MCP server, Playwright MCP server, Semgrep MCP server

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
- Agent config to `~/.kiro/agents/bughunter.json`
- Prompt to `~/.kiro/agents/bughunter-resources/prompt.md`
- Skills to `~/.kiro/skills/bughunter/`

### Manual Installation

1. Copy `bughunter.json` to `~/.kiro/agents/`
2. Copy `prompt.md` to `~/.kiro/agents/bughunter-resources/`
3. Copy the `skills/` folder contents to `~/.kiro/skills/bughunter/`

## Usage

Start a Kiro CLI chat session and switch to the agent:

```
/agent bughunter
```

Then start an engagement:

```
hunt target.com
```

### Workflow Commands

| Command | Purpose |
|---------|---------|
| `hunt <target>` | Start hunting (Red Team vs WAPT dispatcher) |
| `recon <target>` | Full recon pipeline |
| `triage` | Quick 7-Question Gate |
| `validate` | Full 4-gate checklist |
| `report` | Draft submission-ready report |
| `chain` | Build A→B→C exploit chain |
| `autopilot` | Autonomous hunt loop |
| `scope <asset>` | Verify asset is in scope |
| `surface <target>` | Ranked attack surface |
| `pickup <target>` | Resume previous hunt |
| `intel <target>` | CVE/disclosed-report intel |
| `remember` | Log finding to hunt memory |
| `memory-gc` | Inspect/rotate hunt-memory files |
| `token-scan` | Meme-coin/token security scan |
| `web3-audit <contract>` | Smart-contract checklist |

### Coverage

- Web apps, APIs, GraphQL, OAuth, JWT, file upload, IDOR, SSRF, RCE
- Enterprise identity: M365/Entra ID, Okta, SAML SSO
- Infrastructure: VMware vCenter, SSL VPNs
- Cloud: AWS/Azure/GCP IAM, public S3, IMDS
- Mobile: Android APK red-team pipeline
- Supply chain: dep-confusion, GH Actions, SBOM mining

## Uninstalling

**Windows:**
```powershell
Remove-Item "$env:USERPROFILE\.kiro\agents\bughunter.json"
Remove-Item -Recurse "$env:USERPROFILE\.kiro\agents\bughunter-resources"
Remove-Item -Recurse "$env:USERPROFILE\.kiro\skills\bughunter"
```

**Linux/macOS:**
```bash
rm ~/.kiro/agents/bughunter.json
rm -rf ~/.kiro/agents/bughunter-resources
rm -rf ~/.kiro/skills/bughunter
```
