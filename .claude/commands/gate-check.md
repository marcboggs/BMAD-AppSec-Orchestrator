---
description: Manually evaluate the quality gate for the current engagement phase — shows criteria, pass/fail per criterion, and a recommendation.
---

# /gate-check

Read `reports/engagement.json` to find `current_phase`. Evaluate the gate for that phase against the criteria below, show each criterion's pass/fail, and recommend: proceed, loop back (name which agent to re-run and why), or halt.

- **discover → analyze:** at least one complete scan (secreview or iac-audit) with parseable output
- **analyze → plan:** all trust zones identified and mapped to a framework control; all data flows modeled; STRIDE categories addressed per component; Critical/High discovery findings represented as threats; Critical/High architecture risks (`SA-*`) traced into the threat model; attack surface enumeration covers all external interfaces
- **plan → execute:** plan reviewed by threat-model for attack-surface completeness; **explicit user approval obtained** (never assume this — ask if not already given)
- **execute → report:** every finding has reproduction steps; severity confirmed (not just scanner output); false positives marked and excluded; PoC evidence attached or referenced

If the same criterion has failed 3 times, say so explicitly and escalate to the user for a manual decision rather than looping again. Update `reports/engagement.json`'s `quality_gates` entry for the phase with the result.
