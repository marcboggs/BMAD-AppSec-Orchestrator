---
description: Show current security engagement progress — phase, agent run status, findings count by severity, and quality gate status.
---

# /status

Read `reports/engagement.json`. If it doesn't exist, tell the user no engagement is active and suggest `/engage <target>`.

Otherwise report:
- Current phase and which agents have run vs. are pending, by checking for output under `reports/<agent-name>/`
- Findings count by severity (aggregate across `reports/*/**/findings.json` and report frontmatter where present)
- Quality gate status for each completed phase (from `reports/engagement.json`'s `quality_gates`)
- What's next in the lifecycle
