#!/usr/bin/env python3
"""
hooklog.py — kiro-cli hook logger for post-mortem forensics.

Purpose
-------
Anthropic models sometimes refuse a request on cybersecurity grounds and kill
the session mid-turn. When that happens you get no structured "here is the
action I was about to take". This hook writes an append-only breadcrumb to disk
*before* each tool runs (preToolUse) and at the end of each turn (stop), so the
LAST line in the log is the action / response the agent was on when the session
died.

Wiring (in an agent JSON `hooks` block)
----------------------------------------
    "preToolUse": [ { "matcher": "*",
        "command": "python \"~/.kiro/agents/<agent>-resources/hooklog.py\" <agent>" } ],
    "stop":       [ {
        "command": "python \"~/.kiro/agents/<agent>-resources/hooklog.py\" <agent>" } ]

The single positional arg is the agent name, used only to name the log file.
kiro-cli passes the hook event as JSON on STDIN and sets KIRO_SESSION_ID.

Output
------
One JSON object per line, appended to:
    ~/.kiro/logs/<agent>-actions.log

Privacy / safety
----------------
SANITIZED BY DEFAULT. Tool arguments and assistant responses are NOT written
verbatim — they are reduced to length + SHA-256 + a few safe fields (tool name,
path, url, command name). This matters because these agents (skill-reviewer,
bughunter) legitimately handle jailbreak/exploit strings; writing those verbatim
is exactly the content that can trip a safety block, and you don't want your
forensic log to become a second copy of it.

Set  KIRO_HOOK_LOG_VERBOSE=1  to log full payloads (use only while actively
debugging a specific kill).

Guarantees
----------
- Never blocks or fails a tool: always exits 0, even on malformed input or I/O
  errors. A logging hook must never break the agent.
- Standard library only. Works on Windows and POSIX.
"""

import sys
import os
import json
import hashlib
import datetime


def _now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def _sha256(text):
    return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()


def _summarize_tool_input(tool_input):
    """Return a sanitized summary of tool_input without leaking payloads."""
    summary = {}
    if not isinstance(tool_input, dict):
        blob = json.dumps(tool_input, ensure_ascii=False, default=str)
        return {"arg_bytes": len(blob.encode("utf-8", "replace")), "sha256": _sha256(blob)}

    # Pull a few low-risk, high-signal fields when present.
    for key in ("path", "url", "mode"):
        if key in tool_input and isinstance(tool_input[key], (str, int, float)):
            summary[key] = tool_input[key]

    # read tool: operations[].path
    ops = tool_input.get("operations")
    if isinstance(ops, list):
        paths = [op.get("path") for op in ops if isinstance(op, dict) and op.get("path")]
        if paths:
            summary["paths"] = paths[:10]

    # shell tool: log only the command *name* (first token), not full args.
    for cmd_key in ("command", "cmd"):
        cmd = tool_input.get(cmd_key)
        if isinstance(cmd, str) and cmd.strip():
            summary["command_name"] = cmd.strip().split()[0]
            break

    # Always include size + hash of the full serialized input for correlation.
    blob = json.dumps(tool_input, ensure_ascii=False, default=str)
    summary["arg_bytes"] = len(blob.encode("utf-8", "replace"))
    summary["sha256"] = _sha256(blob)
    return summary


def build_record(agent, event):
    ev = event.get("hook_event_name", "unknown")
    verbose = os.environ.get("KIRO_HOOK_LOG_VERBOSE", "").strip() in ("1", "true", "yes")

    rec = {
        "ts": _now_iso(),
        "session": os.environ.get("KIRO_SESSION_ID", ""),
        "agent": agent,
        "event": ev,
        "cwd": event.get("cwd", ""),
    }

    if ev in ("preToolUse", "postToolUse"):
        rec["tool"] = event.get("tool_name", "")
        tool_input = event.get("tool_input")
        if verbose:
            rec["tool_input"] = tool_input
        else:
            rec["tool_input_summary"] = _summarize_tool_input(tool_input)
        if ev == "postToolUse":
            resp = event.get("tool_response")
            if verbose:
                rec["tool_response"] = resp
            else:
                blob = json.dumps(resp, ensure_ascii=False, default=str)
                rec["tool_response_summary"] = {
                    "bytes": len(blob.encode("utf-8", "replace")),
                    "sha256": _sha256(blob),
                }
    elif ev == "stop":
        resp = event.get("assistant_response", "")
        if not isinstance(resp, str):
            resp = json.dumps(resp, ensure_ascii=False, default=str)
        if verbose:
            rec["assistant_response"] = resp
        else:
            rec["assistant_response_summary"] = {
                "chars": len(resp),
                "sha256": _sha256(resp),
                "preview": resp[:80],   # short, non-sensitive lead-in for orientation
            }
    elif ev in ("userPromptSubmit",):
        prompt = event.get("prompt", "")
        if not isinstance(prompt, str):
            prompt = json.dumps(prompt, ensure_ascii=False, default=str)
        if verbose:
            rec["prompt"] = prompt
        else:
            rec["prompt_summary"] = {"chars": len(prompt), "sha256": _sha256(prompt)}

    return rec


def main():
    # Agent name = first positional arg; default to "agent" if omitted.
    agent = sys.argv[1] if len(sys.argv) > 1 else "agent"

    try:
        raw = sys.stdin.read()
    except Exception:
        return 0
    if not raw.strip():
        return 0

    try:
        event = json.loads(raw)
    except Exception:
        # Still leave a breadcrumb that *something* happened, unparsed.
        event = {"hook_event_name": "unparsed", "raw_bytes": len(raw)}

    try:
        record = build_record(agent, event) if isinstance(event, dict) else {
            "ts": _now_iso(), "agent": agent, "event": "non-object-event"}
    except Exception as e:
        record = {"ts": _now_iso(), "agent": agent, "event": "hooklog-error", "error": str(e)}

    try:
        log_dir = os.path.join(os.path.expanduser("~"), ".kiro", "logs")
        os.makedirs(log_dir, exist_ok=True)
        log_path = os.path.join(log_dir, f"{agent}-actions.log")
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception:
        # Logging must never break the tool/turn.
        return 0

    return 0


if __name__ == "__main__":
    # Force exit 0 no matter what — a hook returning non-zero surfaces a warning
    # (preToolUse=2 would even BLOCK the tool). We only ever want to observe.
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
