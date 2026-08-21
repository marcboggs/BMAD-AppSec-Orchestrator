#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the iac-audit Kiro agent.
# IaC Audit has no agent dependencies — it is a standalone scanner.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

AGENT_NAME="iac-audit"
AGENT_LABEL="IaC Audit"
AGENT_DESC="Infrastructure-as-Code security auditor"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
RESOURCES_DIR="$KIRO_AGENTS_DIR/${AGENT_NAME}-resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m' DIM='\033[2m' CYAN='\033[36m' GREEN='\033[32m' RESET='\033[0m'

header() {
    echo ""
    echo -e "  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}   🏗️  ${BOLD}${AGENT_LABEL}${RESET} — ${AGENT_DESC}   ${CYAN}│${RESET}"
    echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}
step()  { echo -e "  ${DIM}●${RESET} $1"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
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
info "No agent dependencies (standalone scanner)"
echo ""

mkdir -p "$KIRO_AGENTS_DIR" "$RESOURCES_DIR"

step "Installing agent files..."
cp "$SCRIPT_DIR/${AGENT_NAME}.json" "$KIRO_AGENTS_DIR/${AGENT_NAME}.json"
ok "Config  → ~/.kiro/agents/${AGENT_NAME}.json"
cp "$SCRIPT_DIR/prompt.md" "$RESOURCES_DIR/prompt.md"
ok "Prompt  → ~/.kiro/agents/${AGENT_NAME}-resources/prompt.md"

footer
