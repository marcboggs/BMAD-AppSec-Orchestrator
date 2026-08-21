# Security Agent Suite for Kiro CLI

Nine security-focused Kiro agents orchestrated using the **BMAD methodology** (Breakthrough Method of Agile AI-Driven Development) — specialized personas with structured handoffs, quality gates, and iterative feedback loops across the full security lifecycle.

## BMAD Methodology

This suite adapts BMAD's multi-agent orchestration framework for security engagements:

- **Specialized Personas** — Each agent has a defined identity, communication style, and expertise domain
- **Structured Artifacts** — Standardized report schemas with cross-references (`[SR-SAST-003]`, `[TM-T4]`)
- **Quality Gates** — Mandatory validation checkpoints before work flows downstream
- **Feedback Loops** — Agents iteratively refine each other's output (findings feed back to update models)
- **Orchestration** — A coordinator agent sequences work, enforces gates, and decides what to run

### Engagement Lifecycle

```mermaid
graph LR
    subgraph "Phase 1: SCOPE"
        S[Define targets<br/>Select agents<br/>Confirm boundaries]
    end

    subgraph "Phase 2: DISCOVER"
        D1[secreview<br/>SAST/SCA]
        D2[iac-audit<br/>IaC scan]
    end

    subgraph "Phase 3: ANALYZE"
        A1[threat-model<br/>STRIDE]
        A2[api-spec-review<br/>API Top 10]
        A3[supply-chain<br/>Deps & CI/CD]
    end

    subgraph "Phase 4: PLAN"
        P[pentest-planner<br/>Test cases]
    end

    subgraph "Phase 5: EXECUTE"
        E[bughunter<br/>Red-team]
    end

    subgraph "Phase 6: REPORT"
        R[compliance<br/>Regulatory map]
    end

    S --> D1
    S --> D2
    D1 -->|Gate: Triage| A1
    D2 -.-> R
    A1 --> A2
    A1 --> A3
    A1 -->|Gate: Model complete| P
    A2 --> P
    A3 --> P
    P -->|Gate: User approval| E
    E -->|Gate: Findings validated| R

    style S fill:#2c3e50,stroke:#3498db,color:#ecf0f1
    style D1 fill:#1a5276,stroke:#2980b9,color:#ecf0f1
    style D2 fill:#1a5276,stroke:#2980b9,color:#ecf0f1
    style A1 fill:#1e8449,stroke:#27ae60,color:#ecf0f1
    style A2 fill:#1e8449,stroke:#27ae60,color:#ecf0f1
    style A3 fill:#1e8449,stroke:#27ae60,color:#ecf0f1
    style P fill:#7d3c98,stroke:#a569bd,color:#ecf0f1
    style E fill:#922b21,stroke:#e74c3c,color:#ecf0f1
    style R fill:#b9770e,stroke:#f39c12,color:#ecf0f1
```

### Quality Gates

```mermaid
graph TD
    G1{{"🚦 Gate 1: DISCOVER → ANALYZE<br/>Are Critical/High findings triaged?"}}
    G2{{"🚦 Gate 2: ANALYZE → PLAN<br/>Is threat model complete?"}}
    G3{{"🚦 Gate 3: PLAN → EXECUTE<br/>Has user approved the plan?"}}
    G4{{"🚦 Gate 4: EXECUTE → REPORT<br/>Are findings validated with PoC?"}}

    G1 -->|Pass| ANALYZE[Proceed to Analyze]
    G1 -->|Fail| RETRIAGE[Re-triage with orchestrator]
    G2 -->|Pass| PLAN[Proceed to Plan]
    G2 -->|Fail| REMODEL[Loop: Re-run threat-model]
    G3 -->|Pass| EXECUTE[Proceed to Execute]
    G3 -->|Fail| REPLAN[Loop: Revise plan]
    G4 -->|Pass| REPORT[Proceed to Report]
    G4 -->|Fail| REVALIDATE[Loop: Revalidate findings]

    style G1 fill:#f39c12,stroke:#e67e22,color:#000
    style G2 fill:#f39c12,stroke:#e67e22,color:#000
    style G3 fill:#f39c12,stroke:#e67e22,color:#000
    style G4 fill:#f39c12,stroke:#e67e22,color:#000
```

### Feedback Loops

```mermaid
graph TD
    SR[secreview] -->|findings| TM[threat-model]
    TM -->|validation request| PP[pentest-planner]
    PP -->|attack surface check| TM
    PP -->|execution plan| BH[bughunter]
    BH -->|"validated findings<br/>(model update)"| TM
    CO[compliance] -->|"control gap<br/>re-scan request"| SR

    style SR fill:#1a5276,stroke:#2980b9,color:#fff
    style TM fill:#1e8449,stroke:#27ae60,color:#fff
    style PP fill:#7d3c98,stroke:#a569bd,color:#fff
    style BH fill:#922b21,stroke:#e74c3c,color:#fff
    style CO fill:#b9770e,stroke:#f39c12,color:#fff
```

## Agents

| Agent | Role | Persona | Depends on |
|-------|------|---------|------------|
| **security-orchestrator** | Engagement coordinator | Senior security program manager | — |
| **secreview** | SAST/SCA reviewer | AppSec engineer, zero false-positive tolerance | — |
| **iac-audit** | IaC scanner | Cloud security architect, CIS-grounded | — |
| **bughunter** | Red-team operator | Senior pentester, evidence-mandatory | secreview |
| **api-spec-review** | API security reviewer | API specialist, spec-driven | secreview |
| **supply-chain** | Dependency & CI/CD auditor | Supply chain researcher, reachability-focused | secreview |
| **threat-model** | STRIDE modeler | AppSec architect, scan-corroborated | secreview |
| **compliance** | Regulatory mapper | GRC specialist, auditor-readable | secreview, threat-model |
| **pentest-planner** | Pentest plan generator | Engagement manager, intelligence-driven | secreview, threat-model, bughunter |

### Agent Dependency Graph

```mermaid
graph TD
    SO[🎼 security-orchestrator<br/><i>Coordinator</i>]
    SR[🔒 secreview<br/><i>SAST/SCA</i>]
    IA[🏗️ iac-audit<br/><i>IaC Scanner</i>]
    BH[🐛 bughunter<br/><i>Red-team</i>]
    API[📋 api-spec-review<br/><i>API Security</i>]
    SC[📦 supply-chain<br/><i>Dep & CI/CD</i>]
    TM[🛡️ threat-model<br/><i>STRIDE</i>]
    CO[📜 compliance<br/><i>Regulatory</i>]
    PP[🎯 pentest-planner<br/><i>Test Plans</i>]

    SO -.->|orchestrates| SR
    SO -.->|orchestrates| IA
    SO -.->|orchestrates| TM
    SO -.->|orchestrates| BH
    SO -.->|orchestrates| CO
    SO -.->|orchestrates| PP

    SR --> BH
    SR --> API
    SR --> SC
    SR --> TM
    SR --> CO
    SR --> PP
    TM --> CO
    TM --> PP
    BH --> PP

    style SO fill:#2c3e50,stroke:#ecf0f1,color:#ecf0f1
    style SR fill:#1a5276,stroke:#2980b9,color:#fff
    style IA fill:#1a5276,stroke:#2980b9,color:#fff
    style BH fill:#7d3c98,stroke:#a569bd,color:#fff
    style API fill:#7d3c98,stroke:#a569bd,color:#fff
    style SC fill:#7d3c98,stroke:#a569bd,color:#fff
    style TM fill:#1e8449,stroke:#27ae60,color:#fff
    style CO fill:#b9770e,stroke:#f39c12,color:#fff
    style PP fill:#b9770e,stroke:#f39c12,color:#fff
```

### Structured Artifacts & Cross-References

Each agent writes to a standard output path and uses a cross-reference prefix:

| Agent | Output | Prefix | Example Reference |
|-------|--------|--------|-------------------|
| secreview | `reports/secreview/` | SR | `[SR-SAST-003]` |
| iac-audit | `reports/iac-audit/` | IAC | `[IAC-007]` |
| bughunter | `reports/bughunter/` | BH | `[BH-SQLI-001]` |
| api-spec-review | `reports/api-spec-review/` | API | `[API-BOLA-002]` |
| supply-chain | `reports/supply-chain/` | SC | `[SC-CVE-2024-1234]` |
| threat-model | `reports/threat-models/` | TM | `[TM-T4]` |
| compliance | `reports/compliance/` | CO | `[CO-PCI-6.2]` |
| pentest-planner | `reports/pentest-plans/` | PP | `[PP-TC-012]` |

See [`reports-schema.md`](reports-schema.md) for the full artifact format specification.

### Typical End-to-End Workflow (Orchestrated)

```mermaid
sequenceDiagram
    participant User
    participant Orch as security-orchestrator
    participant SR as secreview
    participant IA as iac-audit
    participant TM as threat-model
    participant PP as pentest-planner
    participant BH as bughunter
    participant CO as compliance

    User->>Orch: /engage ./my-app (full-stack)
    activate Orch
    Orch->>User: Confirm scope + agent selection
    User->>Orch: Approved

    Note over Orch: Phase 2: DISCOVER
    Orch->>SR: Scan source code
    Orch->>IA: Scan IaC files
    SR-->>Orch: 12 findings (3 Critical)
    IA-->>Orch: 5 findings (1 Critical)

    Note over Orch: 🚦 Gate 1: Triage
    Orch->>Orch: Critical/High → Analyze

    Note over Orch: Phase 3: ANALYZE
    Orch->>TM: Build threat model (with SR findings)
    TM-->>Orch: STRIDE matrix (8 threats)

    Note over Orch: 🚦 Gate 2: Model complete?
    Orch->>Orch: ✓ All flows modeled

    Note over Orch: Phase 4: PLAN
    Orch->>PP: Generate pentest plan
    PP->>TM: Validate attack surface
    TM-->>PP: ✓ Covers all vectors
    PP-->>Orch: Plan (15 test cases, ~40h)
    Orch->>User: Review plan?

    Note over Orch: 🚦 Gate 3: User approval
    User->>Orch: Approved

    Note over Orch: Phase 5: EXECUTE
    Orch->>BH: Execute plan
    BH-->>Orch: 7 validated findings

    Note over Orch: 🚦 Gate 4: Findings validated?
    Orch->>Orch: ✓ All have PoC

    Note over Orch: Feedback: Update model
    Orch->>TM: Update with BH findings

    Note over Orch: Phase 6: REPORT
    Orch->>CO: Map to SOC2 + PCI-DSS
    CO-->>Orch: Compliance report

    Orch->>User: Engagement complete ✓
    deactivate Orch
```

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed and configured
- Recommended: [Semgrep](https://semgrep.dev) for automated SAST
- Recommended: [checkov](https://www.checkov.io/) or [trivy](https://trivy.dev/) for IaC scanning
- Optional: Burp Suite, Playwright, and Semgrep MCP servers (for bughunter)

## Install All

### Windows (PowerShell)

```powershell
.\install-all.ps1
```

### Linux / macOS (Bash)

```bash
chmod +x install-all.sh
./install-all.sh
```

Agents are installed in dependency order — each agent's requirements are satisfied before it installs.

## Install Individually

Each agent can be installed separately. Dependencies are checked and auto-installed from sibling directories:

```powershell
# Windows — no-dependency agents
.\secreview\install.ps1
.\iac-audit\install.ps1
.\security-orchestrator\install.ps1

# Depends on secreview (auto-installed if missing)
.\bughunter\install.ps1
.\api-spec-review\install.ps1
.\supply-chain\install.ps1
.\threat-model\install.ps1

# Multiple dependencies (auto-installed if missing)
.\compliance\install.ps1          # needs: secreview, threat-model
.\pentest-planner\install.ps1     # needs: secreview, threat-model, bughunter
```

```bash
# Linux / macOS
./secreview/install.sh
./iac-audit/install.sh
./security-orchestrator/install.sh
./bughunter/install.sh
./api-spec-review/install.sh
./supply-chain/install.sh
./threat-model/install.sh
./compliance/install.sh
./pentest-planner/install.sh
```

## Quick Start (Orchestrated)

```bash
# Start the orchestrator — it handles everything
kiro chat --agent security-orchestrator
> /engage ./my-application

# Or run agents individually
kiro chat --agent secreview
> review ./src
```

## Directory Structure

```
.
├── README.md                        ← This file
├── reports-schema.md                ← BMAD artifact format specification
├── install-all.ps1                  ← Install all (Windows)
├── install-all.sh                   ← Install all (Linux/macOS)
├── security-orchestrator/           ← Orchestrator (BMAD coordinator)
├── secreview/                       ← Layer 1: Base SAST/SCA agent
├── iac-audit/                       ← Layer 1: IaC scanner (standalone)
├── bughunter/                       ← Layer 2: Red-team operator
│   └── skills/                      ← 51 skill folders + 14 commands
├── api-spec-review/                 ← Layer 2: API security reviewer
├── supply-chain/                    ← Layer 2: Dependency & CI/CD auditor
├── threat-model/                    ← Layer 3: STRIDE threat modeler
│   └── resources/                   ← Templates + STRIDE reference
├── compliance/                      ← Layer 4: Regulatory mapper
└── pentest-planner/                 ← Layer 4: Pentest plan generator
```

## Individual Agent Docs

- [`security-orchestrator/`](security-orchestrator/) — Engagement lifecycle coordinator
- [`secreview/README.md`](secreview/README.md) — SAST workflow and output format
- [`iac-audit/`](iac-audit/) — IaC scanning (Terraform, Docker, K8s)
- [`bughunter/README.md`](bughunter/README.md) — Full command reference and coverage
- [`api-spec-review/`](api-spec-review/) — OWASP API Top 10 analysis
- [`supply-chain/`](supply-chain/) — Dependency, SBOM, and CI/CD security
- [`threat-model/README.md`](threat-model/README.md) — STRIDE workflow and report format
- [`compliance/`](compliance/) — Regulatory framework mapping
- [`pentest-planner/`](pentest-planner/) — Pentest plan generation

## Uninstalling

**Windows:**
```powershell
@("security-orchestrator","secreview","iac-audit","bughunter","api-spec-review",
  "supply-chain","threat-model","compliance","pentest-planner") | ForEach-Object {
    Remove-Item "$env:USERPROFILE\.kiro\agents\$_.json" -ErrorAction SilentlyContinue
    Remove-Item -Recurse "$env:USERPROFILE\.kiro\agents\$_-resources" -ErrorAction SilentlyContinue
}
Remove-Item -Recurse "$env:USERPROFILE\.kiro\skills\bughunter" -ErrorAction SilentlyContinue
```

**Linux/macOS:**
```bash
for agent in security-orchestrator secreview iac-audit bughunter api-spec-review \
             supply-chain threat-model compliance pentest-planner; do
    rm -f ~/.kiro/agents/${agent}.json
    rm -rf ~/.kiro/agents/${agent}-resources
done
rm -rf ~/.kiro/skills/bughunter
```
