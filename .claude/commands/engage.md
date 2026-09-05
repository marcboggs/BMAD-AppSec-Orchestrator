---
description: Start a new security engagement — scopes targets, selects agents, and drives the full Scope → Discover → Analyze → Plan → Execute → Report lifecycle with quality gates.
argument-hint: <target> [web app|API|IaC-only|full-stack]
---

# /engage

Run this in the main session (not as a delegated subagent) so you can pause for the user's approval at each quality gate — that live back-and-forth is the point of this command.

Target: $ARGUMENTS

## Phase 1 — Scope

1. If no engagement type was given, ask: "web app | API | IaC-only | full-stack?"
2. Identify target directories, URLs, specs, and IaC files from the argument given.
3. Select which of the 9 specialist agents apply, using this decision table:

| Project Type | secreview | iac-audit | security-architecture | threat-model | api-spec-review | supply-chain | pentest-planner | bughunter | compliance |
|-------------|:---------:|:---------:|:---------------------:|:------------:|:---------------:|:------------:|:---------------:|:---------:|:----------:|
| Web App | required | if applicable | required | required | if applicable | required | required | required | required |
| API | required | if applicable | required | required | required | required | required | required | required |
| IaC-only | skip | required | if applicable | required | skip | if applicable | if applicable | if applicable | required |
| Full-stack | required | required | required | required | required | required | required | required | required |

Auto-detect: `*.tf`/CloudFormation/Dockerfile/`k8s/` → iac-audit; `openapi.yaml`/`swagger.json`/`*.graphql` → api-spec-review; `package.json`/`requirements.txt`/`go.mod`/`Cargo.toml` → supply-chain; external URLs in scope → bughunter; design docs/ADRs/multi-service topology → security-architecture.

4. Write the engagement manifest to `reports/engagement.json` (schema below).
5. **Confirm scope with the user before proceeding to Discover.**

```json
{
  "engagement_id": "<uuid>",
  "created": "<ISO-8601>",
  "type": "web-app | api | iac-only | full-stack",
  "targets": { "directories": [], "urls": [], "specs": [], "iac": [] },
  "agents_selected": [],
  "current_phase": "scope",
  "quality_gates": {
    "discover": { "status": "pending" },
    "analyze": { "status": "pending" },
    "plan": { "status": "pending" },
    "execute": { "status": "pending" }
  },
  "findings_summary": { "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0 }
}
```

## Phase 2 — Discover

Invoke via the `Agent` tool (parallel where possible):
- `subagent_type: "secreview"` — SAST/SCA on source
- `subagent_type: "iac-audit"` — if IaC in scope

**Gate:** at least one complete scan with parseable output, or halt and report. Update `reports/engagement.json` gate status.

## Phase 3 — Analyze

Sequentially invoke:
1. `subagent_type: "security-architecture"` (if applicable)
2. `subagent_type: "threat-model"` (after security-architecture, so its risk register anchors STRIDE)
3. `subagent_type: "api-spec-review"` and `subagent_type: "supply-chain"` (parallel, if applicable)

**Gate:** all trust zones identified, all data flows modeled, Critical/High discovery findings represented as threats, attack surface fully enumerated. If incomplete, loop back into security-architecture/threat-model with the specific gap named.

## Phase 4 — Plan

Invoke `subagent_type: "pentest-planner"`. Send the resulting plan to `subagent_type: "threat-model"` for attack-surface validation; regenerate if it finds untested vectors.

**Gate — user approval required.** Present: test case count, tools required, estimated time, disruption risk, out-of-scope exclusions. **Do not proceed to Execute without explicit confirmation.**

## Phase 5 — Execute

Invoke `subagent_type: "bughunter"` with the approved plan. Only test in-scope items; stop immediately on unexpected access or data exposure.

**Gate:** every finding has repro steps, confirmed severity, false positives excluded, PoC attached. Feed validated findings back into `subagent_type: "threat-model"` for a model update.

## Phase 6 — Report

Invoke `subagent_type: "compliance"` to map all validated findings to the relevant frameworks (SOC2/PCI-DSS/HIPAA/NIST 800-53). If it surfaces control gaps uncovered by prior scans, trigger a targeted `secreview` re-scan.

Update `reports/engagement.json` after every phase. Never silently skip a phase — tell the user what deviated from the plan and why.
