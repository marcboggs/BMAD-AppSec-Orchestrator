# Session Action Logging (post-mortem for safety-blocked sessions)

Anthropic models sometimes refuse a request on cybersecurity grounds and **kill
the session mid-turn**. You get no structured "here is the action I was about to
take." This suite ships a small hook logger that writes an append-only
breadcrumb **before every tool call** (`preToolUse`) and **at the end of every
turn** (`stop`), so after a kill the **last line of the log is what the agent
was doing** when it died.

It uses kiro-cli's documented [Hooks System](https://kiro.dev) —
`preToolUse` / `stop` hooks receive the event as JSON on STDIN and have
`KIRO_SESSION_ID` in the environment. The logger is standard-library Python and
works on Windows and POSIX.

## Where it logs

```
~/.kiro/logs/<agent>-actions.log      # one JSON object per line (JSONL)
```

Each line includes: ISO timestamp, `KIRO_SESSION_ID`, agent, event
(`preToolUse` / `postToolUse` / `stop`), tool name, `cwd`, and a **sanitized**
summary of the tool input / assistant response.

## Enabled by default

`skill-reviewer` and `bughunter` ship with the hooks already wired in and the
`hooklog.py` script installed to their `-resources/` dir. Nothing to do — after
a killed session, open:

```
~/.kiro/logs/skill-reviewer-actions.log
~/.kiro/logs/bughunter-actions.log
```

…and read the last entry (and the `stop` entry preview) to see the triggering
action.

## Sanitized by default (important for security agents)

By default the log does **not** contain raw tool arguments or assistant text —
only tool name, path/url, a command *name* (first token), byte/char length, an
80-char preview (for `stop`), and a **SHA-256** for correlation. This is
deliberate: these agents legitimately handle jailbreak/exploit strings, and you
don't want your forensic log to become a second on-disk copy of the very content
that tripped the block.

When you're actively debugging a specific kill and need the full payload, set:

```bash
# POSIX
export KIRO_HOOK_LOG_VERBOSE=1
```
```powershell
# Windows PowerShell
$env:KIRO_HOOK_LOG_VERBOSE = "1"
```

…in the shell that launches `kiro-cli`, then reproduce. Verbose mode logs full
`tool_input` and `assistant_response`. Unset it when done.

## Turning it on for the other agents (troubleshooting opt-in)

The other 9 agents don't log by default. To enable logging for any of them
(e.g. `secreview`, `threat-model`, `iac-audit`, …) while chasing a kill:

### 1. Copy the script into that agent's resources dir

The canonical script lives at `hooks/hooklog.py` in this repo. Copy it to the
installed agent's resources directory (create the dir if needed):

```bash
# POSIX — replace <agent> with the agent name, e.g. secreview
mkdir -p ~/.kiro/agents/<agent>-resources
cp hooks/hooklog.py ~/.kiro/agents/<agent>-resources/hooklog.py
mkdir -p ~/.kiro/logs
```
```powershell
# Windows PowerShell
$a = "<agent>"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.kiro\agents\$a-resources" | Out-Null
Copy-Item hooks\hooklog.py "$env:USERPROFILE\.kiro\agents\$a-resources\hooklog.py" -Force
New-Item -ItemType Directory -Force "$env:USERPROFILE\.kiro\logs" | Out-Null
```

### 2. Add the hooks to that agent's config

Edit `~/.kiro/agents/<agent>.json` and add (or merge into) a `hooks` block.
Replace **both** occurrences of `<agent>` with the agent name:

```json
"hooks": {
  "preToolUse": [
    {
      "matcher": "*",
      "command": "python \"~/.kiro/agents/<agent>-resources/hooklog.py\" <agent>"
    }
  ],
  "stop": [
    {
      "command": "python \"~/.kiro/agents/<agent>-resources/hooklog.py\" <agent>"
    }
  ]
}
```

If the agent already has a `hooks` block (e.g. an `agentSpawn` echo), just add
the `preToolUse` and `stop` keys alongside it.

### 3. Save — that's it

kiro-cli **hot-reloads** agent config changes into the running session (no
restart, conversation preserved). The next tool call is logged. To turn logging
off again, remove the `preToolUse`/`stop` keys and save.

> Note: on Windows the hook command uses `python`; ensure Python 3.8+ is on
> PATH. If your Python launcher is `py`, change `python` to `py` in the command.

## Reading a log after a kill

```bash
# last 5 actions before the session died
tail -n 5 ~/.kiro/logs/skill-reviewer-actions.log

# pretty-print the very last entry
tail -n 1 ~/.kiro/logs/skill-reviewer-actions.log | python -m json.tool
```

The last `preToolUse` entry is the tool the agent was about to run; the last
`stop` entry's `preview`/`sha256` identifies the response turn. Correlate by the
`session` field (matches `KIRO_SESSION_ID` and the
`~/.kiro/sessions/cli/<session-id>.jsonl` transcript).

## Guarantees

- The hook **never blocks or fails a tool** — `hooklog.py` always exits 0, even
  on malformed input or I/O errors. A logging hook must never break the agent.
- Standard-library Python only; no dependencies.
