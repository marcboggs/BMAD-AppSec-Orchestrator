#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Uninstalls the full Security Agent Suite from Kiro CLI (10 agents).
#
# Each agent's install.sh writes three things into ~/.kiro:
#     ~/.kiro/agents/<name>.json
#     ~/.kiro/agents/<name>-resources/
#     ~/.kiro/skills/<name>/
# This uninstaller removes exactly those, for every agent this repo ships. The
# agent list is derived from each */install.sh (AGENT_NAME=...), so it stays in
# sync with the suite automatically.
#
#   ./uninstall-all.sh            # confirm, then remove
#   ./uninstall-all.sh --dry-run  # list what would be removed, change nothing
#   ./uninstall-all.sh --yes      # skip the confirmation prompt
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_AGENTS_DIR="$HOME/.kiro/agents"
KIRO_SKILLS_DIR="$HOME/.kiro/skills"

BOLD='\033[1m'; DIM='\033[2m'; CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

DRY_RUN=0; ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --yes|-y)     ASSUME_YES=1 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo -e "  ${RED}Unknown option: $arg${RESET}" >&2; exit 2 ;;
    esac
done

echo ""
echo -e "  ${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
echo -e "  ${CYAN}│${RESET}   🧹  ${BOLD}Uninstall Security Agent Suite (Kiro CLI)${RESET}         ${CYAN}│${RESET}"
echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
echo ""

# Derive the agent names from each top-level agent dir's install.sh.
AGENTS=()
for installer in "$SCRIPT_DIR"/*/install.sh; do
    name="$(grep -m1 -oE 'AGENT_NAME="[^"]+"' "$installer" 2>/dev/null | sed -E 's/AGENT_NAME="([^"]+)"/\1/')"
    [ -n "$name" ] && AGENTS+=("$name")
done

if [ "${#AGENTS[@]}" -eq 0 ]; then
    echo -e "  ${RED}✗ Could not derive the agent list from */install.sh — run from the repo root.${RESET}"; exit 1
fi

# Collect the paths that actually exist.
TARGETS=()
for name in "${AGENTS[@]}"; do
    for candidate in \
        "$KIRO_AGENTS_DIR/$name.json" \
        "$KIRO_AGENTS_DIR/$name-resources" \
        "$KIRO_SKILLS_DIR/$name"; do
        [ -e "$candidate" ] && TARGETS+=("$candidate")
    done
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
    echo -e "  ${YELLOW}Nothing to remove — no suite files found under ~/.kiro/.${RESET}"
    echo ""; exit 0
fi

echo -e "  ${DIM}The following ${#TARGETS[@]} item(s) will be removed:${RESET}"
echo ""
for t in "${TARGETS[@]}"; do
    echo -e "  ${RED}✗${RESET} ${t/#$HOME/\~}"
done
echo ""

if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${CYAN}Dry run — nothing was changed.${RESET}"
    echo ""; exit 0
fi

if [ "$ASSUME_YES" -ne 1 ]; then
    printf "  %bRemove these items? [y/N]%b " "$YELLOW" "$RESET"
    read -r reply
    case "$reply" in
        [yY]|[yY][eE][sS]) ;;
        *) echo -e "\n  ${DIM}Aborted. Nothing removed.${RESET}\n"; exit 0 ;;
    esac
fi

removed=0
for t in "${TARGETS[@]}"; do
    rm -rf "$t" && removed=$((removed + 1))
done

echo ""
echo -e "  ${GREEN}✓ Removed ${removed} item(s) from ~/.kiro/ (${#AGENTS[@]} agents).${RESET}"
echo -e "  ${DIM}The agents/ and skills/ directories were left in place.${RESET}"
echo ""
