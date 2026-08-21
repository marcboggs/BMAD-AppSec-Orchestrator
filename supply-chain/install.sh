#!/usr/bin/env bash
set -euo pipefail
AGENT_NAME="supply-chain"; AGENT_LABEL="Supply Chain"; AGENT_DESC="Supply chain security analyst"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"; RESOURCES_DIR="$KIRO_AGENTS_DIR/${AGENT_NAME}-resources"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD='\033[1m' DIM='\033[2m' CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m' RESET='\033[0m'
header() { echo -e "\n  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}\n  ${CYAN}│${RESET}   📦  ${BOLD}${AGENT_LABEL}${RESET} — ${AGENT_DESC}          ${CYAN}│${RESET}\n  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n"; }
step() { echo -e "  ${DIM}●${RESET} $1"; }; ok() { echo -e "  ${GREEN}✓${RESET} $1"; }; warn() { echo -e "  ${YELLOW}⚠${RESET} $1"; }; fail() { echo -e "  ${RED}✗${RESET} $1"; }
info() { echo -e "  ${DIM}ℹ $1${RESET}"; }
footer() { echo -e "\n  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}\n  ${GREEN}│  ✓  ${AGENT_LABEL} installed successfully                 │${RESET}\n  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}\n  ${DIM}Run:${RESET} /agent ${AGENT_NAME}\n"; }

header
step "Checking dependencies..."
echo ""
if [ -f "$KIRO_AGENTS_DIR/secreview.json" ]; then ok "secreview is installed"
else
    warn "secreview is required but not installed"
    info "Supply Chain uses secreview SCA output as baseline"
    INSTALLER="$(dirname "$SCRIPT_DIR")/secreview/install.sh"
    if [ -f "$INSTALLER" ]; then echo -e "  ${CYAN}→ Installing secreview...${RESET}"; bash "$INSTALLER"
    else fail "Cannot find secreview installer. Install it first."; exit 1; fi
fi
echo ""

mkdir -p "$KIRO_AGENTS_DIR" "$RESOURCES_DIR"
step "Installing agent files..."
cp "$SCRIPT_DIR/${AGENT_NAME}.json" "$KIRO_AGENTS_DIR/${AGENT_NAME}.json"
ok "Config  → ~/.kiro/agents/${AGENT_NAME}.json"
cp "$SCRIPT_DIR/prompt.md" "$RESOURCES_DIR/prompt.md"
ok "Prompt  → ~/.kiro/agents/${AGENT_NAME}-resources/prompt.md"
footer
