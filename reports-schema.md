# Reports Schema — Security Agent Suite

Standard artifact format for all reports produced by the security agent suite. Every agent writes to and reads from this shared structure to enable cross-referencing, quality tracking, and compliance mapping.

---

## Directory Structure

```
reports/
├── engagement.json                          ← Engagement manifest (orchestrator)
├── secreview/
│   └── <component-slug>/
│       ├── secreview-report.md
│       ├── secreview-report.html
│       └── sca-results.json
├── iac-audit/
│   └── <component-slug>/
│       ├── iac-audit-report.md
│       └── iac-audit-report.html
├── security-architecture/
│   └── <component-slug>/
│       ├── security-architecture-review.md
│       ├── security-architecture-review.html
│       └── findings.json
├── threat-models/
│   └── <component-slug>/
│       ├── threat-model.md
│       └── threat-model.html
├── api-spec-review/
│   └── <component-slug>/
│       ├── api-security-report.md
│       └── api-security-report.html
├── supply-chain/
│   └── <component-slug>/
│       ├── supply-chain-report.md
│       ├── supply-chain-report.html
│       └── sbom.json
├── pentest-plans/
│   └── <component-slug>/
│       ├── pentest-plan.md
│       └── pentest-plan.html
├── bughunter/
│   └── <component-slug>/
│       ├── findings.md
│       ├── findings.html
│       └── pocs/
│           └── <finding-id>.md
├── compliance/
│   └── <component-slug>/
│       ├── compliance-report.md
│       └── compliance-report.html
└── final/
    ├── executive-summary.md
    ├── executive-summary.html
    └── remediation-priorities.md
```

---

## Visualization Standard (Mermaid-Only)

**Mermaid is the single, mandatory visualization format for every report in this suite.**

- **ALL** graphs, charts, diagrams, flows, matrices-as-graphs, timelines, and any other
  visual representation — in **every** report, from **every** agent — MUST be authored as
  [Mermaid](https://mermaid.js.org/) diagrams.
- In Markdown reports, every visual MUST be a fenced ` ```mermaid ` code block.
- In HTML reports, every visual MUST be a `<div class="mermaid">…</div>` block rendered
  client-side via the Mermaid CDN. Reuse the **identical** Mermaid source from the Markdown
  report — never redraw, rasterize, or simplify.
- Use the appropriate Mermaid diagram type for the content, for example:
  - `graph` / `flowchart` — architecture, trust zones, data flow, dependency graphs, attack chains
  - `sequenceDiagram` — auth flows, request/response, exploit steps, agent handoffs
  - `pie` — severity/finding distribution and other proportional charts
  - `gantt` — pentest timelines and remediation roadmaps
  - `stateDiagram-v2` — lifecycle/state transitions
  - `mindmap` / `timeline` — attack-surface breakdowns, engagement timelines
- **Prohibited:** ASCII/box-drawing diagrams, embedded raster images (PNG/JPG/GIF/SVG) used
  as diagrams or charts, screenshots of charts, external chart-image services, or any other
  non-Mermaid rendering of a graph/chart/diagram. (Screenshots that are *evidence* — e.g., a
  bughunter PoC screenshot of an exploited page — are not diagrams and are exempt; do not use
  them to convey structured data that belongs in a Mermaid diagram.)
- If a visual genuinely cannot be expressed in Mermaid, present the information as a Markdown
  table instead — do not fall back to a non-Mermaid image or ASCII art.

This rule is authoritative. Any agent-specific instruction that appears more permissive is
overridden by this section.

---

## Dual Output: Markdown + Standalone HTML

Every agent MUST produce **both** a Markdown report and a standalone HTML report from the same underlying analysis:

1. **Markdown (`.md`)** — Primary artifact with YAML frontmatter, fenced ` ```mermaid ` blocks for **all** visuals (see Visualization Standard above), and standard tables. Used for cross-referencing by other agents and version control diffs.

2. **HTML (`.html`)** — Self-contained standalone report that loads Mermaid via CDN and renders **all** diagrams/charts client-side. Uses a light theme. Suitable for sharing with stakeholders who don't have Markdown renderers.

### HTML Report Requirements

- Load Mermaid from `https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js`
- Initialize with diagram scaling enabled so diagrams render large and readable — do **not** use the bare `mermaid.initialize({ startOnLoad: true, theme: "default" })`. Disable Mermaid's intrinsic width cap, then render with `mermaid.run()` and tag very wide diagrams so they stay legible (see next bullet):
  ```html
  <script>
    mermaid.initialize({
      startOnLoad: false,
      theme: "default",
      themeVariables: { fontSize: "16px" },
      flowchart: { useMaxWidth: false, htmlLabels: true },
      sequence: { useMaxWidth: false },
      gantt: { useMaxWidth: false },
      pie: { useMaxWidth: false }
    });
    // Render, then flag very wide diagrams so they stay legible (larger scale +
    // horizontal scroll) instead of being shrunk to fit the text column.
    mermaid.run().then(() => {
      document.querySelectorAll('.mermaid').forEach(box => {
        const svg = box.querySelector('svg');
        if (!svg) return;
        const vb = (svg.getAttribute('viewBox') || '').split(/\s+/).map(Number);
        const w = vb[2] || svg.getBBox().width;
        const h = vb[3] || svg.getBBox().height;
        if (w && h && (w / h) > 2.2) box.classList.add('wide');
      });
    });
  </script>
  ```
- Include the `.mermaid` sizing CSS so diagrams fill the container width instead of rendering tiny (Mermaid otherwise keeps the SVG at its small intrinsic size). Normal-aspect diagrams fill the width; the `.mermaid.wide` rule keeps very wide diagrams at a legible scale and lets them scroll horizontally rather than being crushed to fit the column:
  ```css
  .mermaid { background: var(--panel); border: 1px solid var(--border); border-radius: 8px;
    padding: 20px; margin: 20px 0; text-align: center; overflow-x: auto; }
  .mermaid svg { width: 100% !important; max-width: 100% !important; height: auto !important;
    min-height: 320px; display: block; margin: 0 auto; }
  /* Very wide diagrams (tagged .wide after render) scroll instead of shrinking. */
  .mermaid.wide svg { width: auto !important; max-width: none !important;
    height: 620px !important; margin: 0; }
  ```
- Prefer top-down (`flowchart TB`) layouts and keep node/edge label text short — extremely wide diagrams are hard to read even with the `.wide` fallback. If a diagram is very wide because of many side-by-side trust zones, consider splitting it into multiple focused diagrams.
- Render **every** graph/chart/diagram as a `<div class="mermaid">` block — no raster images, ASCII art, or external chart services (see Visualization Standard)
- **Reuse identical Mermaid source** from the Markdown report — do not redraw or simplify diagrams
- Use severity badge styling: `.sev-critical`, `.sev-high`, `.sev-medium`, `.sev-low`
- Include report metadata in header (agent, scope, date)
- Include footer citing the generating agent

See `report-template.html` in the repository root for the shared HTML template with CSS and structure.

### Component Slug Convention

The `<component-slug>` is a kebab-case identifier for the target component:
- `auth-service` — for `./src/auth/`
- `main-api` — for the primary API endpoint
- `terraform-infra` — for `./terraform/`
- `global` — when the scan covers the entire project

---

## Required Report Fields

Every report file (Markdown) MUST include these metadata fields in a YAML frontmatter block or as the first structured section:

```markdown
---
title: "SAST Findings — Auth Service"
date: "2026-08-20T08:00:00Z"
scope: "./src/auth/"
agent: "secreview"
status: "draft"
engagement_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
---
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | ✅ | Human-readable report title |
| `date` | ISO-8601 | ✅ | Report generation timestamp |
| `scope` | string | ✅ | What was analyzed (path, URL, spec file) |
| `agent` | string | ✅ | Agent that produced this report |
| `status` | enum | ✅ | Current lifecycle status (see below) |
| `engagement_id` | UUID | ✅ | Links report to engagement manifest |
| `severity_summary` | object | ⚡ | Count by severity (if applicable) |
| `cross_refs` | array | ⚡ | IDs of related findings from other agents |

---

## Cross-Reference Format

Agents cite each other's findings using bracket notation with a standardized ID format:

```
[<AGENT-PREFIX>-<CATEGORY>-<NUMBER>]
```

### Agent Prefixes

| Agent | Prefix | Example |
|-------|--------|---------|
| secreview | `SR` | `[SR-SAST-003]` |
| iac-audit | `IA` | `[IA-MISC-012]` |
| security-architecture | `SA` | `[SA-AUTHZ-001]` |
| threat-model | `TM` | `[TM-STRIDE-007]` |
| api-spec-review | `API` | `[API-BOLA-001]` |
| supply-chain | `SC` | `[SC-DEP-005]` |
| pentest-planner | `PP` | `[PP-TC-014]` |
| bughunter | `BH` | `[BH-VULN-002]` |
| compliance | `CO` | `[CO-SOC2-CC6.1]` |

### Category Codes

| Agent | Categories |
|-------|-----------|
| secreview | `SAST`, `SCA`, `DAST` |
| iac-audit | `MISC` (misconfiguration), `CIS`, `NET`, `IAM`, `ENC` |
| security-architecture | `AUTHN`, `AUTHZ`, `CRYPTO`, `SECRETS`, `SEGMENT`, `DEFENSE`, `EXPOSURE`, `RESILIENCE`, `DATA` |
| threat-model | `STRIDE` (single), `SPOOF`, `TAMPER`, `REPUD`, `INFO`, `DOS`, `ELEV` |
| api-spec-review | `BOLA`, `BFLA`, `INJECT`, `MASS`, `SSRF`, `RATE`, `AUTH` |
| supply-chain | `DEP`, `TYPO`, `CICD`, `SBOM` |
| pentest-planner | `TC` (test case) |
| bughunter | `VULN`, `POC` |
| compliance | Framework-specific (e.g., `SOC2`, `PCI`, `HIPAA`, `NIST`) |

### Cross-Reference Examples

```markdown
## Finding: SQL Injection in User Lookup

**ID:** [BH-VULN-002]
**Severity:** Critical
**Related:** [SR-SAST-003], [TM-STRIDE-007], [API-INJECT-001]

This finding validates the static analysis result [SR-SAST-003] which identified
unsanitized input at `src/api/users.ts:47`. The threat model predicted this
attack vector in [TM-STRIDE-007] under the Tampering category.
```

---

## Quality Gate Section

Every report MUST include a `## Quality Gate` section that tracks whether the report meets the criteria for the current phase transition:

```markdown
## Quality Gate

| Criterion | Status | Notes |
|-----------|--------|-------|
| All targets scanned | ✅ Pass | 3/3 directories scanned |
| Findings triaged by severity | ✅ Pass | 2 Critical, 5 High, 12 Medium |
| False positives reviewed | ⏳ Pending | Awaiting bughunter validation |
| Cross-references resolved | ✅ Pass | All SR-* IDs linked |

**Gate Status:** ⏳ PENDING
**Blocking:** False positive review (requires Execute phase)
```

### Gate Status Values

| Status | Meaning |
|--------|---------|
| ✅ PASS | All criteria met; safe to proceed to next phase |
| ⏳ PENDING | Some criteria not yet evaluated |
| ❌ FAIL | One or more criteria not met; requires action |
| ⚠️ OVERRIDE | User manually approved despite failures |

---

## Artifact Lifecycle

Every report progresses through these statuses:

```
draft → reviewed → validated → final
```

### Status Definitions

| Status | Meaning | Who transitions |
|--------|---------|-----------------|
| `draft` | Initial output from agent | Agent (on creation) |
| `reviewed` | Checked by orchestrator or downstream agent | Orchestrator / dependent agent |
| `validated` | Findings confirmed (e.g., by bughunter execution) | Validating agent |
| `final` | Locked for compliance reporting; no further changes | Orchestrator (on engagement close) |

### Transition Rules

1. **draft → reviewed:** Automatic when a downstream agent reads and incorporates the findings
2. **reviewed → validated:** Requires explicit confirmation (bughunter PoC, user sign-off, or cross-agent corroboration)
3. **validated → final:** Set by orchestrator during `/report-all` when engagement closes
4. Reports may regress: `validated → draft` if new information invalidates previous findings

---

## Finding Severity Scale

All agents use a unified severity scale:

| Severity | CVSS Range | Color | Response |
|----------|-----------|-------|----------|
| Critical | 9.0 – 10.0 | 🔴 | Immediate remediation required |
| High | 7.0 – 8.9 | 🟠 | Remediation within current sprint |
| Medium | 4.0 – 6.9 | 🟡 | Scheduled remediation |
| Low | 0.1 – 3.9 | 🔵 | Track and address opportunistically |
| Info | 0.0 | ⚪ | Informational; no action required |

---

## Machine-Readable Companion Files

For structured data, agents SHOULD produce JSON companions alongside Markdown reports:

```json
{
  "report_id": "SR-auth-service-20260820",
  "agent": "secreview",
  "engagement_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "draft",
  "generated_at": "2026-08-20T08:00:00Z",
  "scope": "./src/auth/",
  "findings": [
    {
      "id": "SR-SAST-003",
      "title": "SQL Injection in User Lookup",
      "severity": "critical",
      "cvss": 9.8,
      "location": "src/api/users.ts:47",
      "cwe": "CWE-89",
      "description": "Unsanitized user input passed to SQL query",
      "remediation": "Use parameterized queries",
      "cross_refs": ["TM-STRIDE-007"],
      "status": "draft"
    }
  ],
  "quality_gate": {
    "status": "pass",
    "criteria": {
      "all_targets_scanned": true,
      "findings_triaged": true,
      "cross_refs_resolved": true
    }
  }
}
```

---

## Conventions

1. **File naming:** Use kebab-case for all file and directory names
2. **Timestamps:** Always ISO-8601 with timezone (`2026-08-20T08:00:00Z`)
3. **IDs are immutable:** Once assigned, a finding ID never changes (even if severity is updated)
4. **Append-only logs:** Never delete findings; mark as `false_positive: true` if invalid
5. **Encoding:** UTF-8 for all files; no BOM in Markdown/JSON
6. **Line endings:** LF (`\n`) for all report files regardless of platform
