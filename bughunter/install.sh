#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the bughunter Kiro agent.
# REQUIRES: secreview (spawned as subagent for SAST/SCA).
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
AGENT_NAME="bughunter"
AGENT_LABEL="BugHunter"
AGENT_DESC="Bug bounty / red-team operator"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
RESOURCES_DIR="$KIRO_AGENTS_DIR/${AGENT_NAME}-resources"
SKILLS_DIR="$HOME/.kiro/skills/${AGENT_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── TUI Helpers ─────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

header() {
    echo ""
    echo -e "  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│                                                        │${RESET}"
    echo -e "  ${CYAN}│${RESET}   🐛  ${BOLD}${AGENT_LABEL}${RESET} — ${AGENT_DESC}          ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│                                                        │${RESET}"
    echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

step()    { echo -e "  ${DIM}●${RESET} $1"; }
ok()      { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $1"; }
fail()    { echo -e "  ${RED}✗${RESET} $1"; }
info()    { echo -e "  ${DIM}ℹ $1${RESET}"; }

footer() {
    echo ""
    echo -e "  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${GREEN}│  ✓  ${AGENT_LABEL} installed successfully                       │${RESET}"
    echo -e "  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${DIM}Run:${RESET} ${YELLOW}/agent ${AGENT_NAME}${RESET}"
    echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────
header

# ─── Dependency: secreview (MANDATORY) ───────────────────────────────────────
step "Checking dependencies..."
echo ""

if [ -f "$KIRO_AGENTS_DIR/secreview.json" ]; then
    ok "secreview is installed"
else
    warn "secreview is required but not installed"
    info "BugHunter spawns secreview for SAST/SCA scanning"
    echo ""

    SECREVIEW_INSTALLER="$(dirname "$SCRIPT_DIR")/secreview/install.sh"
    if [ -f "$SECREVIEW_INSTALLER" ]; then
        echo -e "  ${CYAN}→ Installing secreview dependency...${RESET}"
        echo ""
        bash "$SECREVIEW_INSTALLER"
    else
        fail "Cannot find secreview installer at: $(dirname "$SCRIPT_DIR")/secreview/install.sh"
        echo ""
        echo -e "  ${RED}Install secreview first:${RESET}"
        echo -e "    ${DIM}cd $(dirname "$SCRIPT_DIR")/secreview && ./install.sh${RESET}"
        echo ""
        exit 1
    fi
fi
echo ""

# ─── Create directories ─────────────────────────────────────────────────────
step "Preparing directories..."
mkdir -p "$KIRO_AGENTS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$SKILLS_DIR"

# ─── Install files ───────────────────────────────────────────────────────────
step "Installing agent files..."
cp "$SCRIPT_DIR/${AGENT_NAME}.json" "$KIRO_AGENTS_DIR/${AGENT_NAME}.json"
ok "Config  → ~/.kiro/agents/${AGENT_NAME}.json"

cp "$SCRIPT_DIR/prompt.md" "$RESOURCES_DIR/prompt.md"
ok "Prompt  → ~/.kiro/agents/${AGENT_NAME}-resources/prompt.md"

# Skills
if [ -d "$SCRIPT_DIR/skills" ]; then
    step "Installing skills..."
    cp -r "$SCRIPT_DIR/skills/"* "$SKILLS_DIR/"
    skill_count=$(find "$SKILLS_DIR" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
    ok "Skills  → ~/.kiro/skills/${AGENT_NAME}/ (${skill_count} folders)"
fi

footer
