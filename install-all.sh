#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Installs the full Security Agent Suite for Kiro CLI (11 agents).
# Installs in dependency order so each agent's deps are satisfied.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"

BOLD='\033[1m' DIM='\033[2m' CYAN='\033[36m' GREEN='\033[32m' MAGENTA='\033[35m' RESET='\033[0m'

banner() {
    echo ""
    echo -e "  ${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${MAGENTA}│                                                        │${RESET}"
    echo -e "  ${MAGENTA}│     🔐  ${BOLD}Security Agent Suite for Kiro CLI${RESET}${MAGENTA}          │${RESET}"
    echo -e "  ${MAGENTA}│                                                        │${RESET}"
    echo -e "  ${MAGENTA}│     Installing 11 agents in dependency order            │${RESET}"
    echo -e "  ${MAGENTA}│                                                        │${RESET}"
    echo -e "  ${MAGENTA}│     Orchestrator: security-orchestrator                 │${RESET}"
    echo -e "  ${MAGENTA}│     Layer 1: secreview, iac-audit, skill-reviewer       │${RESET}"
    echo -e "  ${MAGENTA}│     Layer 2: bughunter, api-spec-review, supply-chain   │${RESET}"
    echo -e "  ${MAGENTA}│     Layer 3: threat-model, security-architecture        │${RESET}"
    echo -e "  ${MAGENTA}│     Layer 4: compliance, pentest-planner                │${RESET}"
    echo -e "  ${MAGENTA}│                                                        │${RESET}"
    echo -e "  ${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

phase() {
    local num=$1 total=$2 name=$3
    echo ""
    echo -e "  ${CYAN}── [$num/$total] $name ──────────────────────────────────────${RESET}"
    echo ""
}

summary() {
    echo ""
    echo -e "  ${GREEN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${GREEN}│                                                        │${RESET}"
    echo -e "  ${GREEN}│  ✓  All 11 agents installed successfully!              │${RESET}"
    echo -e "  ${GREEN}│                                                        │${RESET}"
    echo -e "  ${GREEN}│  /agent security-orchestrator → Start here!            │${RESET}"
    echo -e "  ${GREEN}│  /agent secreview       → SAST/SCA reviewer            │${RESET}"
    echo -e "  ${GREEN}│  /agent iac-audit       → IaC security scanner         │${RESET}"
    echo -e "  ${GREEN}│  /agent skill-reviewer  → Skill/prompt trust review    │${RESET}"
    echo -e "  ${GREEN}│  /agent bughunter       → Red-team operator            │${RESET}"
    echo -e "  ${GREEN}│  /agent api-spec-review → API security (OWASP Top 10)  │${RESET}"
    echo -e "  ${GREEN}│  /agent supply-chain    → Dependency & CI/CD audit     │${RESET}"
    echo -e "  ${GREEN}│  /agent security-architecture → Design review          │${RESET}"
    echo -e "  ${GREEN}│  /agent threat-model    → STRIDE modeling              │${RESET}"
    echo -e "  ${GREEN}│  /agent compliance      → Regulatory mapping           │${RESET}"
    echo -e "  ${GREEN}│  /agent pentest-planner → Pentest plan generator       │${RESET}"
    echo -e "  ${GREEN}│                                                        │${RESET}"
    echo -e "  ${GREEN}└────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

banner
run_preflight

# Orchestrator: No dependencies
phase 1 11 "Security Orchestrator"
bash "$SCRIPT_DIR/security-orchestrator/install.sh"

# Layer 1: No dependencies
phase 2 11 "SecReview (base)"
bash "$SCRIPT_DIR/secreview/install.sh"

phase 3 11 "IaC Audit (standalone)"
bash "$SCRIPT_DIR/iac-audit/install.sh"

phase 4 11 "Skill Reviewer (standalone)"
bash "$SCRIPT_DIR/skill-reviewer/install.sh"

# Layer 2: Depends on secreview
phase 5 11 "BugHunter (→ secreview)"
bash "$SCRIPT_DIR/bughunter/install.sh"

phase 6 11 "API Spec Review (→ secreview)"
bash "$SCRIPT_DIR/api-spec-review/install.sh"

phase 7 11 "Supply Chain (→ secreview)"
bash "$SCRIPT_DIR/supply-chain/install.sh"

# Layer 3: Depends on secreview (via installer chain)
phase 8 11 "Threat Model (→ secreview)"
bash "$SCRIPT_DIR/threat-model/install.sh"

phase 9 11 "Security Architecture (→ secreview)"
bash "$SCRIPT_DIR/security-architecture/install.sh"

# Layer 4: Multiple deps
phase 10 11 "Compliance (→ secreview, threat-model)"
bash "$SCRIPT_DIR/compliance/install.sh"

phase 11 11 "Pentest Planner (→ secreview, threat-model, bughunter)"
bash "$SCRIPT_DIR/pentest-planner/install.sh"

summary
