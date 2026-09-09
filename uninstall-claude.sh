#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Uninstalls the Security Agent Suite from Claude Code (user-level).
#
# install-claude.sh merges this suite's files into the SHARED ~/.claude/{agents,
# skills,commands} directories, which may also hold agents/skills/commands you
# added yourself. So this uninstaller removes ONLY the entries this repo ships —
# computed live from .claude/ — and never deletes those directories themselves.
#
#   ./uninstall-claude.sh            # confirm, then remove
#   ./uninstall-claude.sh --dry-run  # list what would be removed, change nothing
#   ./uninstall-claude.sh --yes      # skip the confirmation prompt
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
SRC="$SCRIPT_DIR/.claude"

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
echo -e "  ${CYAN}│${RESET}   🧹  ${BOLD}Uninstall Security Agent Suite (Claude Code)${RESET}      ${CYAN}│${RESET}"
echo -e "  ${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
echo ""

if [ ! -d "$SRC" ]; then
    echo -e "  ${RED}✗ Cannot find $SRC — run this from the repo root.${RESET}"; exit 1
fi

# Build the list of installed paths from what the repo ships. Each entry is a
# top-level name under agents/skills/commands; we remove the matching entry in
# ~/.claude/. `resources` under agents/ is shipped by this suite too.
TARGETS=()
for sub in agents skills commands; do
    [ -d "$SRC/$sub" ] || continue
    while IFS= read -r -d '' entry; do
        name="$(basename "$entry")"
        candidate="$CLAUDE_HOME/$sub/$name"
        [ -e "$candidate" ] && TARGETS+=("$candidate")
    done < <(find "$SRC/$sub" -mindepth 1 -maxdepth 1 -print0)
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
    echo -e "  ${YELLOW}Nothing to remove — no suite files found under $CLAUDE_HOME.${RESET}"
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
echo -e "  ${GREEN}✓ Removed ${removed} item(s) from ~/.claude/${RESET}"
echo -e "  ${DIM}The agents/, skills/, and commands/ directories were left in place${RESET}"
echo -e "  ${DIM}(they may hold your own files). MCP servers in project .mcp.json${RESET}"
echo -e "  ${DIM}or ~/.claude.json are not touched — remove those with 'claude mcp remove'.${RESET}"
echo ""
