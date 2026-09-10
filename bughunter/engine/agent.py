#!/usr/bin/env python3
"""
agent.py — the engine's LLM dispatch. Only recon/hunt/validate are model-driven;
the orchestrator, scope, and state are deterministic code.

Dual-CLI: the engine runs on either Kiro CLI (`kiro-cli chat --no-interactive`)
or Claude Code (`claude -p`). It auto-detects which binary is on PATH (Kiro
preferred), or you can force one with $KBH_AGENT_CLI=kiro-cli|claude. Skills
auto-activate; Burp MCP is the hands. Agents are asked to end with a fenced
```json``` block which we parse into structured data.
"""
import json
import os
import re
import shutil
import subprocess
import time

ENGINE = os.path.dirname(os.path.abspath(__file__))
MCP_CONFIG = os.path.join(ENGINE, "burp-mcp.json")

# Claude Code tool-allowlist syntax (mcp__server__tool + Bash(cmd:*)).
ALLOWED_TOOLS = " ".join([
    "mcp__burp__send_http1_request", "mcp__burp__send_http2_request",
    "mcp__burp__get_collaborator_interactions", "mcp__burp__generate_collaborator_payload",
    "Bash(curl:*)", "Bash(python3:*)", "Bash(jq:*)", "Bash(openssl:*)", "Bash(base64:*)",
])

# Default model. Overridable per call and via $KBH_MODEL.
DEFAULT_MODEL = os.environ.get("KBH_MODEL", "claude-sonnet-4-6")


def _detect_cli():
    """Which agent CLI to dispatch to. $KBH_AGENT_CLI forces a choice; otherwise
    prefer kiro-cli (this is the Kiro port), then fall back to claude."""
    forced = os.environ.get("KBH_AGENT_CLI")
    if forced:
        return forced
    for cli in ("kiro-cli", "claude"):
        if shutil.which(cli):
            return cli
    return "kiro-cli"  # nothing found; report a clean exec error on run below


def _build_cmd(cli, task, skills_on, model, max_turns):
    """Build the argv for the selected CLI. Kiro and Claude Code have different
    non-interactive flag surfaces, so we map to each rather than share flags."""
    if cli == "claude":
        cmd = ["claude", "-p", task,
               "--mcp-config", MCP_CONFIG, "--strict-mcp-config",
               "--permission-mode", "bypassPermissions",
               "--allowedTools", ALLOWED_TOOLS,
               "--max-turns", str(max_turns), "--model", model,
               "--output-format", "json"]
        if not skills_on:
            cmd.append("--disable-slash-commands")
        return cmd
    # kiro-cli: one-shot non-interactive chat as the bughunter agent. Kiro reads
    # its own MCP config and the agent's own allowedTools from bughunter.json, so
    # the Claude-Code-only flags (--mcp-config/--strict-mcp-config/--allowedTools/
    # --permission-mode/--disable-slash-commands) are intentionally dropped.
    cmd = ["kiro-cli", "chat", "--no-interactive", "--agent", "bughunter"]
    if model:
        cmd += ["--model", model]
    cmd.append(task)
    return cmd


def _parse_kiro(stdout):
    """Kiro's --no-interactive prints the assistant's final text to stdout (not a
    Claude-Code JSON envelope). Try to parse a JSON envelope first (Claude Code /
    future Kiro json mode); otherwise treat stdout as the raw result text."""
    try:
        d = json.loads(stdout)
        if isinstance(d, dict) and "result" in d:
            return d.get("result") or "", d
    except Exception:
        pass
    return stdout, None


def run_agent(task, skills_on=False, model=None, max_turns=40, timeout=600, cli=None):
    # skills OFF by default: the eval showed they add ~0 capability but cost ~12-15k tokens/agent.
    model = model or DEFAULT_MODEL
    cli = cli or _detect_cli()
    cmd = _build_cmd(cli, task, skills_on, model, max_turns)
    t0 = time.time()
    # Explicit missing-binary check (cross-platform): Windows and POSIX differ on
    # whether subprocess raises for a missing exe, so resolve it up front and return
    # a structured error rather than relying on the exception path.
    if shutil.which(cmd[0]) is None:
        return {"result": "", "error": f"exec:{cmd[0]} not found on PATH", "cli": cli,
                "duration_s": round(time.time() - t0, 1)}
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"result": "", "error": "timeout", "cli": cli, "duration_s": round(time.time() - t0, 1)}
    except (FileNotFoundError, OSError) as e:
        # e.g. the selected CLI isn't installed / not on PATH — return a structured
        # error instead of raising, so a single missing binary can't crash the phase.
        return {"result": "", "error": f"exec:{e}", "cli": cli, "duration_s": round(time.time() - t0, 1)}
    res, envelope = _parse_kiro(p.stdout) if cli != "claude" else (None, None)
    try:
        if cli == "claude":
            d = json.loads(p.stdout)
            res = d.get("result") or ""
            envelope = d
        # usage-limit / API errors come back as a short result with no real work
        if res and ("usage limit" in res.lower() or "session limit" in res.lower()):
            return {"result": res, "error": "rate-limited", "cli": cli, "duration_s": round(time.time() - t0, 1)}
        return {"result": res or "",
                "cost_usd": (envelope or {}).get("total_cost_usd"),
                "num_turns": (envelope or {}).get("num_turns"), "error": None,
                "cli": cli, "duration_s": round(time.time() - t0, 1)}
    except Exception as e:
        return {"result": p.stdout[:300], "error": f"parse:{e}", "cli": cli,
                "duration_s": round(time.time() - t0, 1)}


def extract_json(text):
    """Pull the last valid JSON array/object out of an agent reply."""
    if not text:
        return None
    blocks = re.findall(r"```json\s*(.*?)```", text, re.S)
    blocks += re.findall(r"```\s*(\[.*?\]|\{.*?\})\s*```", text, re.S)
    for b in reversed(blocks):
        try:
            return json.loads(b.strip())
        except Exception:
            pass
    for b in reversed(re.findall(r"(\[.*\]|\{.*\})", text, re.S)):
        try:
            return json.loads(b)
        except Exception:
            pass
    return None


if __name__ == "__main__":
    # offline self-test of the JSON extractor (no agent call)
    assert extract_json('blah ```json\n[{"a":1}]\n``` end') == [{"a": 1}]
    assert extract_json('text {"x": "y"} more') == {"x": "y"}
    assert extract_json("no json here") is None
    assert extract_json('first {"a":1} then ```json\n{"b":2}\n```') == {"b": 2}  # prefers fenced/last
    print("agent.py extractor self-test: PASS")
