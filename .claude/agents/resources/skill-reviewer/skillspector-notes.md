# Optional deep scanner integration (SkillSpector)

`skill-reviewer` is **fully self-contained** and works with only the bundled
`prefilter.py` plus the agent's own semantic reasoning. It has **no dependency**
on any external project or on any sibling directory in this repo.

If a heavyweight static+LLM skill scanner happens to be installed on the host,
the agent MAY use it as an *additional* evidence line. The reference integration
is NVIDIA **SkillSpector** (`skillspector` CLI / MCP server), but any equivalent
tool can be slotted in. This is strictly optional and runtime-detected.

## Detect it

```bash
command -v skillspector    # present?  then it can be used
```

If absent, say so plainly in the report ("deep scanner not installed — using
bundled pre-filter + semantic review only") and continue. Its absence lowers
*coverage confidence*, never blocks a verdict.

## Use it (read-only, JSON)

```bash
skillspector scan "$TARGET" --no-llm --format json --output /tmp/skr-deep.json
# or, if LLM analysis is configured on the host and the user consents:
skillspector scan "$TARGET" --format json --output /tmp/skr-deep.json
```

Read from the JSON: `risk_assessment.score` (0–100),
`risk_assessment.severity` (LOW|MEDIUM|HIGH|CRITICAL),
`risk_assessment.recommendation` (SAFE|CAUTION|DO_NOT_INSTALL), and the per-issue
`issues[]` (id, category, severity, confidence, location).

## Map its recommendation to the agent verdict

| Deep-scanner recommendation | Default agent posture |
|---|---|
| SAFE | lean APPROVE (still confirm semantically) |
| CAUTION | CAUTION unless every finding is explained |
| DO_NOT_INSTALL | lean REJECT unless clearly justified & bounded |

The deep-scanner score is *risk posture*, not the verdict. The agent's own
semantic review (idiom, translation, reference-following, permission fit) and
the bundled pre-filter leads are combined into the final APPROVE / CAUTION /
REJECT call per `prompt.md`.

## Trust / egress caveats to state in the report

- Some deep scanners send file contents to an LLM provider when LLM mode is on.
  Prefer `--no-llm` by default; only enable LLM mode with explicit user consent,
  and disclose it in the report.
- A low score from a static-only (`--no-llm`) run is **not** the same as a clean
  full scan — note which mode ran.
- The scanner never executes the skill, and neither do you.
