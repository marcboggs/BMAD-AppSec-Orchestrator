---
description: Generate the final consolidated engagement report — invokes compliance mapping, produces an executive summary and remediation priority list.
---

# /report-all

1. Invoke `subagent_type: "compliance"` via the `Agent` tool with all validated findings from every agent that ran this engagement (check `reports/engagement.json` for `agents_selected` and pull from each `reports/<agent-name>/` directory).
2. Produce an executive summary: overall risk posture, critical/high counts, engagement scope, key business-impact findings.
3. Generate a remediation priority list ordered by severity × exploitability across all agents' findings, not just compliance's.
4. Write output to `reports/final/executive-summary.md`, `reports/final/executive-summary.html`, and `reports/final/remediation-priorities.md`, following the Mermaid-only visualization standard in `reports-schema.md`.
5. Update `reports/engagement.json`'s `current_phase` to `report` and mark the engagement complete.
