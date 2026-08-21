#!/usr/bin/env bash
set -euo pipefail

AGENT_NAME="security-orchestrator"
AGENT_LABEL="Security Orchestrator"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
RESOURCES_DIR="$KIRO_AGENTS_DIR/$AGENT_NAME-resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── TUI Helpers ──────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
WHITE="\033[97m"

banner() {
    echo ""
    echo -e "  ${CYAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${BOLD}${WHITE}Security Orchestrator Installer${RESET}                     ${CYAN}║${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${DIM}Coordinates the 8-agent security suite${RESET}              ${CYAN}║${RESET}"
    echo -e "  ${CYAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

step() {
    echo -e "  ${YELLOW}>>${RESET} ${WHITE}$1${RESET}"
}

success() {
    echo -e "  ${GREEN}[OK]${RESET} $1"
}

fail() {
    echo -e "  ${RED}[!!]${RESET} ${RED}$1${RESET}"
}

# ── Main ─────────────────────────────────────────────────────────────────────
banner

# Verify source files
JSON_SOURCE="$SCRIPT_DIR/$AGENT_NAME.json"
PROMPT_SOURCE="$SCRIPT_DIR/prompt.md"

if [[ ! -f "$JSON_SOURCE" ]]; then
    fail "Missing $AGENT_NAME.json in script directory"
    exit 1
fi
if [[ ! -f "$PROMPT_SOURCE" ]]; then
    fail "Missing prompt.md in script directory"
    exit 1
fi

# Create directories
step "Creating agent directories..."
mkdir -p "$KIRO_AGENTS_DIR"
mkdir -p "$RESOURCES_DIR"
success "Directories ready"

# Copy agent config
step "Installing agent config..."
cp "$JSON_SOURCE" "$KIRO_AGENTS_DIR/$AGENT_NAME.json"
success "$AGENT_NAME.json installed"

# Copy prompt
step "Installing system prompt..."
cp "$PROMPT_SOURCE" "$RESOURCES_DIR/prompt.md"
success "prompt.md installed"

# Verify installation
step "Verifying installation..."
ALL_GOOD=true
if [[ ! -f "$KIRO_AGENTS_DIR/$AGENT_NAME.json" ]]; then
    fail "Agent config not found"
    ALL_GOOD=false
fi
if [[ ! -f "$RESOURCES_DIR/prompt.md" ]]; then
    fail "Prompt not found"
    ALL_GOOD=false
fi

if [[ "$ALL_GOOD" == "true" ]]; then
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────────${RESET}"
    success "$AGENT_LABEL installed successfully!"
    echo ""
    echo -e "  ${DIM}Usage:${RESET}"
    echo -e "    ${CYAN}kiro chat --agent $AGENT_NAME${RESET}"
    echo ""
else
    echo ""
    fail "Installation incomplete — check errors above."
    exit 1
fi
