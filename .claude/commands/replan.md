---
description: Regenerate the pentest plan incorporating new findings or scope changes (new attack surface from bughunter, added targets, or an updated threat model).
---

# /replan

Re-invoke `subagent_type: "pentest-planner"` via the `Agent` tool, giving it:
- The existing plan at `reports/pentest-plans/<engagement-slug>/pentest-plan.md` (if present) as prior context
- Whatever changed: new bughunter-discovered attack surface, user-added targets, or an updated threat model
- Instruction to produce a revised plan that traces every test case to a current finding/threat, same as the original `/engage` Phase 4 logic

Send the revised plan to `subagent_type: "threat-model"` for attack-surface validation before presenting it to the user for re-approval. Update `reports/engagement.json`'s `plan` gate back to `pending` until the user re-approves.
