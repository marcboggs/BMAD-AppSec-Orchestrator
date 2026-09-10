#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the Security Agent Suite for Claude Code (user-level).
#
# Copies .claude/agents, .claude/skills, and .claude/commands from this repo
# into ~/.claude/, so the 10 agents, 86 skills, and 19 slash commands are
# available in every Claude Code project, not just this one.
#
# Unlike the old Kiro installers, there is no dependency order to respect —
# Claude Code subagents can spawn any other subagent that exists in
# ~/.claude/agents/ (or the current project's .claude/agents/) at call time,
# so agents don't need their dependencies pre-installed.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

# shellcheck source=lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"

BOLD='\033[1m'; DIM='\033[2m'; CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RESET='\033[0m'

echo ""
echo -e "  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
echo -e "  ${CYAN}│${RESET}   🔐  ${BOLD}Security Agent Suite for Claude Code${RESET}                ${CYAN}│${RESET}"
echo -e "  ${CYAN}│${RESET}   10 agents · 86 skills · 19 commands (user-level)      ${CYAN}│${RESET}"
echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
echo ""

run_preflight

mkdir -p "$CLAUDE_HOME/agents" "$CLAUDE_HOME/skills" "$CLAUDE_HOME/commands"

echo -e "  ${DIM}●${RESET} Installing agents..."
cp -r "$SCRIPT_DIR/.claude/agents/"* "$CLAUDE_HOME/agents/"
echo -e "  ${GREEN}✓${RESET} 10 agents  → ~/.claude/agents/ (incl. resources/ templates)"

echo -e "  ${DIM}●${RESET} Installing skills..."
cp -r "$SCRIPT_DIR/.claude/skills/"* "$CLAUDE_HOME/skills/"
skill_count=$(find "$CLAUDE_HOME/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${RESET} Skills     → ~/.claude/skills/ (${skill_count} folders)"

echo -e "  ${DIM}●${RESET} Installing commands..."
cp -r "$SCRIPT_DIR/.claude/commands/"* "$CLAUDE_HOME/commands/"
cmd_count=$(find "$CLAUDE_HOME/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${RESET} Commands   → ~/.claude/commands/ (${cmd_count} files)"

echo ""
echo -e "  ${YELLOW}MCP servers (burp/playwright/semgrep) are project-scoped, not copied here.${RESET}"
echo -e "  ${DIM}Run Claude Code from this repo to pick up its .mcp.json, or run:${RESET}"
echo -e "  ${DIM}  claude mcp add playwright -- npx -y @playwright/mcp@latest${RESET}"
echo -e "  ${DIM}  claude mcp add semgrep -- uvx semgrep-mcp${RESET}"
echo -e "  ${DIM}  (see .mcp.json in this repo for the burp entry to fill in)${RESET}"
echo ""
echo -e "  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}"
echo -e "  ${GREEN}│  ✓  Installed. Start Claude Code and try:               │${RESET}"
echo -e "  ${GREEN}│     /engage ./my-app  (full engagement, main session)   │${RESET}"
echo -e "  ${GREEN}│     Agent tool → subagent_type: secreview  (one agent)  │${RESET}"
echo -e "  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}"
echo ""
