#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Tests for the install / uninstall scripts.
#
# These focus on the one risky thing in this repo: the uninstallers run
# `rm -rf` inside the user's real ~/.kiro and ~/.claude. So every test runs the
# REAL installer and uninstaller against a throwaway fake $HOME (a mktemp dir),
# never your actual home directory, and checks three promises:
#
#   1. install then uninstall leaves nothing of the suite behind,
#   2. files YOU put in those shared dirs are never touched,
#   3. --dry-run changes nothing on disk.
#
# Run it standalone, from anywhere:
#     ./tests/run.sh
#
# Exit code is 0 if every check passed, 1 otherwise. No dependencies beyond
# bash + coreutils — no test framework to install.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail   # deliberately NOT -e: we want to run every check and tally

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[32m'; RED='\033[31m'; DIM='\033[2m'; BOLD='\033[1m'; CYAN='\033[36m'; RESET='\033[0m'

pass=0; fail=0

# ─── Tiny assertion helpers ──────────────────────────────────────────────────
# Each prints a ✓/✗ line and bumps the counters. $1 is always a human label.
ok()  { printf "    ${GREEN}✓${RESET} %s\n" "$1"; pass=$((pass + 1)); }
bad() { printf "    ${RED}✗ %s${RESET}\n" "$1"; fail=$((fail + 1)); }

assert_exists() {  # assert_exists PATH LABEL
    [ -e "$1" ] && ok "$2" || bad "$2 — expected to exist: $1"
}
assert_absent() {  # assert_absent PATH LABEL
    [ ! -e "$1" ] && ok "$2" || bad "$2 — should have been removed: $1"
}
assert_eq() {      # assert_eq ACTUAL EXPECTED LABEL
    [ "$1" = "$2" ] && ok "$3" || bad "$3 — expected '$2', got '$1'"
}

group() { printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$1"; }

# Make a fresh fake home for one test and echo its path.
new_home() { mktemp -d "${TMPDIR:-/tmp}/suite-test.XXXXXX"; }

# Run a repo script with HOME pointed at the fake home, output hidden unless it
# errors (in which case we surface a hint and fail loudly).
run_in_home() {  # run_in_home FAKEHOME SCRIPT [args...]
    local home="$1"; shift
    local script="$1"; shift
    if ! HOME="$home" bash "$REPO_ROOT/$script" "$@" >/dev/null 2>&1; then
        bad "$script $* exited non-zero (re-run without >/dev/null to see why)"
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Agent list stays in sync with the installers
#    The Kiro uninstaller derives its agent list from each */install.sh. If that
#    derivation ever breaks, the uninstaller silently removes nothing — so pin
#    both the count and the exact names here.
# ─────────────────────────────────────────────────────────────────────────────
test_agent_list_derivation() {
    group "Kiro agent list is derived correctly from */install.sh"

    local expected="api-spec-review bughunter compliance iac-audit pentest-planner secreview security-architecture security-orchestrator supply-chain threat-model"

    local names=()
    local installer
    for installer in "$REPO_ROOT"/*/install.sh; do
        local n
        n="$(grep -m1 -oE 'AGENT_NAME="[^"]+"' "$installer" 2>/dev/null | sed -E 's/AGENT_NAME="([^"]+)"/\1/')"
        [ -n "$n" ] && names+=("$n")
    done

    assert_eq "${#names[@]}" "10" "finds 10 agents"

    local got
    got="$(printf '%s\n' "${names[@]}" | sort | tr '\n' ' ' | sed 's/ $//')"
    assert_eq "$got" "$expected" "names match the shipped suite"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Kiro: install → uninstall round-trip
# ─────────────────────────────────────────────────────────────────────────────
test_kiro_roundtrip() {
    group "Kiro install-all.sh → uninstall-all.sh"

    local H; H="$(new_home)"
    trap 'rm -rf "$H"' RETURN

    run_in_home "$H" install-all.sh || return

    # Sanity: the installer actually put suite files down.
    assert_exists "$H/.kiro/agents/secreview.json"              "install: secreview.json created"
    assert_exists "$H/.kiro/agents/secreview-resources"         "install: secreview resources created"
    assert_exists "$H/.kiro/skills/bughunter"                   "install: bughunter skills created"

    # Plant files the user might own in the SHARED dirs — these must survive.
    echo '{}' > "$H/.kiro/agents/my-own-agent.json"
    mkdir -p  "$H/.kiro/skills/my-own-skill"
    touch     "$H/.kiro/skills/my-own-skill/keep.md"

    run_in_home "$H" uninstall-all.sh --yes || return

    # Every suite path is gone...
    assert_absent "$H/.kiro/agents/secreview.json"      "uninstall: secreview.json removed"
    assert_absent "$H/.kiro/agents/secreview-resources" "uninstall: secreview resources removed"
    assert_absent "$H/.kiro/skills/bughunter"           "uninstall: bughunter skills removed"

    # ...but the user's own files and the parent dirs are untouched.
    assert_exists "$H/.kiro/agents/my-own-agent.json"   "uninstall: foreign agent preserved"
    assert_exists "$H/.kiro/skills/my-own-skill/keep.md" "uninstall: foreign skill preserved"
    assert_exists "$H/.kiro/agents"                     "uninstall: agents/ dir left in place"
    assert_exists "$H/.kiro/skills"                     "uninstall: skills/ dir left in place"
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Kiro: --dry-run must change nothing
# ─────────────────────────────────────────────────────────────────────────────
test_kiro_dry_run() {
    group "Kiro uninstall-all.sh --dry-run touches nothing"

    local H; H="$(new_home)"
    trap 'rm -rf "$H"' RETURN

    run_in_home "$H" install-all.sh || return
    run_in_home "$H" uninstall-all.sh --dry-run || return

    assert_exists "$H/.kiro/agents/secreview.json" "dry-run: suite file still present"
    assert_exists "$H/.kiro/skills/bughunter"      "dry-run: suite skill still present"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Claude: install → uninstall round-trip
# ─────────────────────────────────────────────────────────────────────────────
test_claude_roundtrip() {
    group "Claude install-claude.sh → uninstall-claude.sh"

    local H; H="$(new_home)"
    trap 'rm -rf "$H"' RETURN

    run_in_home "$H" install-claude.sh || return

    assert_exists "$H/.claude/agents/secreview.md"  "install: secreview agent copied"
    assert_exists "$H/.claude/skills"               "install: skills dir populated"
    assert_exists "$H/.claude/commands"             "install: commands dir populated"

    # User-owned entries in the shared dirs.
    echo "mine" > "$H/.claude/agents/my-own-agent.md"
    mkdir -p     "$H/.claude/skills/my-own-skill"
    echo "mine" > "$H/.claude/commands/my-own-cmd.md"

    run_in_home "$H" uninstall-claude.sh --yes || return

    assert_absent "$H/.claude/agents/secreview.md"       "uninstall: suite agent removed"
    assert_exists "$H/.claude/agents/my-own-agent.md"    "uninstall: foreign agent preserved"
    assert_exists "$H/.claude/skills/my-own-skill"       "uninstall: foreign skill preserved"
    assert_exists "$H/.claude/commands/my-own-cmd.md"    "uninstall: foreign command preserved"
    assert_exists "$H/.claude/agents"                    "uninstall: agents/ dir left in place"
    assert_exists "$H/.claude/commands"                  "uninstall: commands/ dir left in place"
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. Claude: --dry-run must change nothing
# ─────────────────────────────────────────────────────────────────────────────
test_claude_dry_run() {
    group "Claude uninstall-claude.sh --dry-run touches nothing"

    local H; H="$(new_home)"
    trap 'rm -rf "$H"' RETURN

    run_in_home "$H" install-claude.sh || return
    run_in_home "$H" uninstall-claude.sh --dry-run || return

    assert_exists "$H/.claude/agents/secreview.md" "dry-run: suite agent still present"
}

# ─── Run everything ──────────────────────────────────────────────────────────
printf "${BOLD}Running installer / uninstaller tests${RESET}\n"
printf "${DIM}(each test uses a throwaway \$HOME under %s)${RESET}\n" "${TMPDIR:-/tmp}"

test_agent_list_derivation
test_kiro_roundtrip
test_kiro_dry_run
test_claude_roundtrip
test_claude_dry_run

printf "\n${BOLD}%d passed, %d failed${RESET}\n" "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
