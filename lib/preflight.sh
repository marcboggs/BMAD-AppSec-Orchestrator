#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# preflight.sh — sourced by the top-level installers (install-all.sh,
# install-claude.sh) to check runtime prerequisites for the Security Agent Suite.
#
# These tools are NOT needed to copy the agent/skill/command files into place —
# they are needed when the agents actually run (the MCP servers and scanners).
# So a missing tool is a WARNING, never a hard failure: the install still
# completes, and the user is told exactly what to install and why.
#
# Usage:
#   source "<repo>/lib/preflight.sh"
#   run_preflight              # prints a report, always returns 0
# ─────────────────────────────────────────────────────────────────────────────

# Colors — reuse the caller's if already set, else define our own.
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${CYAN:=$'\033[36m'}"
: "${GREEN:=$'\033[32m'}"; : "${YELLOW:=$'\033[33m'}"; : "${RED:=$'\033[31m'}"
: "${RESET:=$'\033[0m'}"

# _pf_check <label> <command> <why> <install-hint>
# Prints ✓ if the command is on PATH, ⚠ + guidance otherwise.
# Increments PF_MISSING for each missing tool.
_pf_check() {
    local label="$1" cmd="$2" why="$3" hint="$4"
    if command -v "$cmd" >/dev/null 2>&1; then
        local ver
        ver="$("$cmd" --version 2>/dev/null | head -n1 | tr -d '\n')"
        echo -e "  ${GREEN}✓${RESET} ${label}${ver:+  ${DIM}(${ver})${RESET}}"
    else
        PF_MISSING=$((PF_MISSING + 1))
        echo -e "  ${YELLOW}⚠${RESET} ${label} ${DIM}— not found${RESET}"
        echo -e "      ${DIM}needed for: ${why}${RESET}"
        echo -e "      ${DIM}install:    ${hint}${RESET}"
    fi
}

run_preflight() {
    PF_MISSING=0
    echo -e "  ${CYAN}Checking runtime prerequisites...${RESET}"
    echo ""

    # Node / npx — the playwright MCP server runs via `npx -y @playwright/mcp`.
    _pf_check "node / npx" "npx" \
        "playwright MCP (browser-driven testing)" \
        "https://nodejs.org  or  'nvm install --lts'"

    # uv / uvx — the semgrep MCP server runs via `uvx semgrep-mcp`.
    _pf_check "uv / uvx" "uvx" \
        "semgrep MCP (SAST via secreview/bughunter)" \
        "https://docs.astral.sh/uv/  or  'curl -LsSf https://astral.sh/uv/install.sh | sh'"

    # semgrep — optional standalone CLI; several skills shell out to it directly.
    _pf_check "semgrep" "semgrep" \
        "semgrep-scan skill / direct SAST (optional — uvx can supply it)" \
        "'uv tool install semgrep'  or  'pipx install semgrep'"

    # git — used by recon/source-audit skills that clone or diff repos.
    _pf_check "git" "git" \
        "source-code recon skills (optional)" \
        "your OS package manager (apt/dnf/brew install git)"

    echo ""
    if [ "$PF_MISSING" -eq 0 ]; then
        echo -e "  ${GREEN}All prerequisites present.${RESET}"
    else
        echo -e "  ${YELLOW}${PF_MISSING} prerequisite(s) missing.${RESET} ${DIM}Install continues — these are only"
        echo -e "  needed when the agents run, and the burp/playwright/semgrep MCP"
        echo -e "  servers are project-scoped. Install the above when you need them.${RESET}"
    fi
    echo ""
    return 0
}
