#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the skill-reviewer Kiro agent.
# Skill Reviewer is standalone — no agent dependencies. It ships a
# self-contained, dependency-free pre-filter (prefilter.py) plus steering
# resources. Python 3.8+ on PATH is optional (needed only to run the pre-filter).
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

AGENT_NAME="skill-reviewer"
AGENT_LABEL="Skill Reviewer"
AGENT_DESC="Agent-skill & prompt trust reviewer"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
RESOURCES_DIR="$KIRO_AGENTS_DIR/${AGENT_NAME}-resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m' DIM='\033[2m' CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RESET='\033[0m'

header() {
    echo ""
    echo -e "  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}   🕵️  ${BOLD}${AGENT_LABEL}${RESET} — ${AGENT_DESC}   ${CYAN}│${RESET}"
    echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}
step()  { echo -e "  ${DIM}●${RESET} $1"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $1"; }
info()  { echo -e "  ${DIM}ℹ $1${RESET}"; }
footer() {
    echo ""
    echo -e "  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${GREEN}│  ✓  ${AGENT_LABEL} installed successfully                       │${RESET}"
    echo -e "  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${DIM}Run:${RESET} /agent ${AGENT_NAME}"
    echo ""
}

header
step "Checking prerequisites..."
info "No agent dependencies (standalone reviewer)"
PY_BIN=""
for cand in python3 python py; do
    if command -v "$cand" >/dev/null 2>&1; then PY_BIN="$cand"; break; fi
done
if [ -n "$PY_BIN" ]; then
    info "Python detected ($PY_BIN) — pre-filter is runnable"
else
    warn "Python 3.8+ not found on PATH — install it so the pre-filter can run (agent still works, reduced coverage)"
fi
echo ""

mkdir -p "$KIRO_AGENTS_DIR" "$RESOURCES_DIR"

step "Installing agent files..."
cp "$SCRIPT_DIR/${AGENT_NAME}.json" "$KIRO_AGENTS_DIR/${AGENT_NAME}.json"
ok "Config    → ~/.kiro/agents/${AGENT_NAME}.json"
cp "$SCRIPT_DIR/prompt.md" "$RESOURCES_DIR/prompt.md"
ok "Prompt    → ~/.kiro/agents/${AGENT_NAME}-resources/prompt.md"

step "Installing resources (pre-filter + steering + hook logger)..."
if [ -d "$SCRIPT_DIR/resources" ]; then
    for f in "$SCRIPT_DIR/resources/"*; do
        [ -f "$f" ] || continue
        cp "$f" "$RESOURCES_DIR/$(basename "$f")"
        ok "$(basename "$f")  → ~/.kiro/agents/${AGENT_NAME}-resources/$(basename "$f")"
    done
fi
mkdir -p "$HOME/.kiro/logs"

footer
