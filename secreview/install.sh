#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the secreview Kiro agent.
# SecReview is the base agent — no dependencies.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
AGENT_NAME="secreview"
AGENT_LABEL="SecReview"
AGENT_DESC="SAST/SCA code reviewer"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
RESOURCES_DIR="$KIRO_AGENTS_DIR/${AGENT_NAME}-resources"
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
    echo -e "  ${CYAN}│${RESET}   🔒  ${BOLD}${AGENT_LABEL}${RESET} — ${AGENT_DESC}              ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│                                                        │${RESET}"
    echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

step()    { echo -e "  ${DIM}●${RESET} $1"; }
ok()      { echo -e "  ${GREEN}✓${RESET} $1"; }
info()    { echo -e "  ${DIM}ℹ $1${RESET}"; }

footer() {
    echo ""
    echo -e "  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${GREEN}│  ✓  ${AGENT_LABEL} installed successfully                      │${RESET}"
    echo -e "  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${DIM}Run:${RESET} ${YELLOW}/agent ${AGENT_NAME}${RESET}"
    echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────
header

# No dependencies
step "Checking prerequisites..."
info "No agent dependencies (base agent)"
echo ""

# Create directories
step "Preparing directories..."
mkdir -p "$KIRO_AGENTS_DIR"
mkdir -p "$RESOURCES_DIR"

# Install files
step "Installing agent files..."
cp "$SCRIPT_DIR/${AGENT_NAME}.json" "$KIRO_AGENTS_DIR/${AGENT_NAME}.json"
ok "Config  → ~/.kiro/agents/${AGENT_NAME}.json"

cp "$SCRIPT_DIR/prompt.md" "$RESOURCES_DIR/prompt.md"
ok "Prompt  → ~/.kiro/agents/${AGENT_NAME}-resources/prompt.md"

footer
