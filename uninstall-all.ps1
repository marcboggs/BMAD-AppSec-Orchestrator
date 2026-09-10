<#
.SYNOPSIS
    Uninstalls the full Security Agent Suite from Kiro CLI (10 agents).
.DESCRIPTION
    Each agent's installer writes ~\.kiro\agents\<name>.json,
    ~\.kiro\agents\<name>-resources\, and ~\.kiro\skills\<name>\. This removes
    exactly those, for every agent this repo ships. The agent list is derived
    from each <agent>\install.sh (AGENT_NAME=...), so it stays in sync.
.PARAMETER DryRun
    List what would be removed, change nothing.
.PARAMETER Yes
    Skip the confirmation prompt.
#>
param([switch]$DryRun, [switch]$Yes)

$ErrorActionPreference = "Stop"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$KiroAgentsDir = Join-Path $env:USERPROFILE ".kiro\agents"
$KiroSkillsDir = Join-Path $env:USERPROFILE ".kiro\skills"

Write-Host ""
Write-Host "  ==========================================================" -ForegroundColor Cyan
Write-Host "   Uninstall Security Agent Suite (Kiro CLI)" -ForegroundColor Cyan
Write-Host "  ==========================================================" -ForegroundColor Cyan
Write-Host ""

# Derive agent names from each top-level agent dir's install.sh.
$agents = @()
foreach ($installer in Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object { Join-Path $_.FullName "install.sh" }) {
    if (-not (Test-Path $installer)) { continue }
    $m = Select-String -Path $installer -Pattern 'AGENT_NAME="([^"]+)"' | Select-Object -First 1
    if ($m) { $agents += $m.Matches[0].Groups[1].Value }
}

if ($agents.Count -eq 0) {
    Write-Host "  [X] Could not derive the agent list from */install.sh -- run from the repo root." -ForegroundColor Red; exit 1
}

$targets = @()
foreach ($name in $agents) {
    foreach ($candidate in @(
        (Join-Path $KiroAgentsDir "$name.json"),
        (Join-Path $KiroAgentsDir "$name-resources"),
        (Join-Path $KiroSkillsDir $name))) {
        if (Test-Path $candidate) { $targets += $candidate }
    }
}

if ($targets.Count -eq 0) {
    Write-Host "  Nothing to remove -- no suite files found under ~\.kiro\." -ForegroundColor Yellow
    Write-Host ""; exit 0
}

Write-Host "  The following $($targets.Count) item(s) will be removed:" -ForegroundColor DarkGray
Write-Host ""
foreach ($t in $targets) { Write-Host "  [X] $($t.Replace($env:USERPROFILE,'~'))" -ForegroundColor Red }
Write-Host ""

if ($DryRun) { Write-Host "  Dry run -- nothing was changed." -ForegroundColor Cyan; Write-Host ""; exit 0 }

if (-not $Yes) {
    $reply = Read-Host "  Remove these items? [y/N]"
    if ($reply -notmatch '^(y|yes)$') { Write-Host "`n  Aborted. Nothing removed.`n" -ForegroundColor DarkGray; exit 0 }
}

$removed = 0
foreach ($t in $targets) { Remove-Item -Path $t -Recurse -Force; $removed++ }

Write-Host ""
Write-Host "  [OK] Removed $removed item(s) from ~\.kiro\ ($($agents.Count) agents)." -ForegroundColor Green
Write-Host "  The agents\ and skills\ directories were left in place." -ForegroundColor DarkGray
Write-Host ""
