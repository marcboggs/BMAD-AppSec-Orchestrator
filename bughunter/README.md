# BugHunter Agent for Kiro CLI

A bug-hunting and external red-team operator agent with 86 skills, 14 workflow commands, and 681 disclosed-report patterns across 57 vulnerability classes. Auto-loads relevant skills by keyword.

It also ships a deterministic **engagement engine**, the terminal-native **`kbh` CLI**, and the **disclosed-report pattern library** — ported from Claude-BugHunter and adapted to run on Kiro CLI (with Claude Code still supported).

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed and configured
- The `secreview` agent installed (used as a subagent for SAST/SCA when source is available)
- Optional: **Python 3.9+** on PATH — only needed to run the engagement engine / `kbh` CLI (the agent itself works without it)
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
- Engine, `kbh` CLI, `scripts/`, `pyproject.toml`, and the `disclosed-reports/` library to `~/.kiro/agents/bughunter-resources/`

### Manual Installation

1. Copy `bughunter.json` to `~/.kiro/agents/`
2. Copy `prompt.md` to `~/.kiro/agents/bughunter-resources/`
3. Copy the `skills/` folder contents to `~/.kiro/skills/bughunter/`
4. Copy `engine/`, `kbh/`, `scripts/`, `pyproject.toml`, and `disclosed-reports/` to `~/.kiro/agents/bughunter-resources/`

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

## Engagement Engine & `kbh` CLI

Beyond the LLM-driven agent, BugHunter ships a **deterministic engagement engine** and a terminal-native **`kbh` CLI** (ported from Claude-BugHunter, adapted for Kiro). These need **Python 3.9+** and install to `~/.kiro/agents/bughunter-resources/`.

### The engine (`engine/engine.py`)

A decision-support orchestrator, not an autonomous robot. It maps a target's attack surface deterministically (recon → rank → map), categorizes each finding against the installed `hunt-*` skills, and shows you where to focus. Active hunting is opt-in (`--hunt`) and read-only by default.

```bash
# From ~/.kiro/agents/bughunter-resources/ (or this repo's bughunter/ dir):

# Default: deterministic map only ($0, no agents). Stops with arsenal.md:
python engine/engine.py --scope my-engagement.json

# Dry-run the whole flow with canned output (no agents, no budget):
python engine/engine.py --scope engine/engagement.example.json --mock --hunt

# Opt-in: auto-test the mapped surface with agents (read-only, parallel):
python engine/engine.py --scope my-engagement.json --hunt --parallel 3 --max-hunts 12
```

**Dual-CLI dispatch:** the engine drives an LLM through whichever agent CLI is on PATH — **Kiro CLI** (`kiro-cli chat --no-interactive --agent bughunter`) is preferred, with **Claude Code** (`claude -p`) as a fallback. Force one with `KBH_AGENT_CLI=kiro-cli|claude`; override the model with `KBH_MODEL`.

Safety: scope is a deterministic allowlist enforced at every boundary; hunt/validate agents run **read-only by default** (`--allow-intrusive` lifts this); every confirmed finding is scope-audited for out-of-scope hosts in its PoC.

### The `kbh` CLI (`kbh/cli.py`)

Terminal-native runner for CI/CD, scripted runs, and deterministic verification:

```bash
# From ~/.kiro/agents/bughunter-resources/:
python -m kbh.cli recon hackerone.com                 # passive recon + live-host probe
python -m kbh.cli classify "https://api.t.com/v1/users/42?next=https://evil.com"   # URL → hunt-* skills
python -m kbh.cli triage findings/idor.md             # 7-Question Gate → PASS/DOWNGRADE/KILL
python -m kbh.cli report findings/idor.md --platform bugcrowd --out draft.md
```

### Disclosed-report pattern library (`disclosed-reports/`)

37 curated pattern files (one per vuln class) distilled from 681 disclosed HackerOne reports. `kbh classify` points you at the matching file; the agent's skills reference the same patterns.

### Environment variables

| Variable | Purpose |
|---|---|
| `KBH_AGENT_CLI` | Force `kiro-cli` or `claude` for engine dispatch |
| `KBH_MODEL` | Override the model (default `claude-sonnet-4-6`) |
| `KBH_SKILLS_DIR` | Override skills location (legacy `CBH_SKILLS_DIR` also honored) |
| `KBH_BURP_PROXY` | Route `kbh` HTTP through a Burp proxy (legacy `CBH_BURP_PROXY` honored) |
| `BUGHUNTER_MEMORY_DIR` | Override the autopilot ledger dir (default `~/.kiro/bughunter/memory`) |

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
