<#
.SYNOPSIS
    Uninstalls the Security Agent Suite from Claude Code (user-level).
.DESCRIPTION
    install-claude.ps1 merges this suite into the SHARED ~\.claude\{agents,
    skills,commands} directories, which may also hold files you added yourself.
    This uninstaller removes ONLY the entries this repo ships (computed live from
    .claude\) and never deletes those directories themselves.
.PARAMETER DryRun
    List what would be removed, change nothing.
.PARAMETER Yes
    Skip the confirmation prompt.
#>
param([switch]$DryRun, [switch]$Yes)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$Src        = Join-Path $ScriptDir ".claude"

Write-Host ""
Write-Host "  ==========================================================" -ForegroundColor Cyan
Write-Host "   Uninstall Security Agent Suite (Claude Code)" -ForegroundColor Cyan
Write-Host "  ==========================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $Src)) {
    Write-Host "  [X] Cannot find $Src -- run from the repo root." -ForegroundColor Red; exit 1
}

$targets = @()
foreach ($sub in @("agents","skills","commands")) {
    $srcSub = Join-Path $Src $sub
    if (-not (Test-Path $srcSub)) { continue }
    foreach ($entry in Get-ChildItem -Path $srcSub) {
        $candidate = Join-Path (Join-Path $ClaudeHome $sub) $entry.Name
        if (Test-Path $candidate) { $targets += $candidate }
    }
}

if ($targets.Count -eq 0) {
    Write-Host "  Nothing to remove -- no suite files found under $ClaudeHome." -ForegroundColor Yellow
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
Write-Host "  [OK] Removed $removed item(s) from ~\.claude\" -ForegroundColor Green
Write-Host "  The agents\, skills\, and commands\ directories were left in place." -ForegroundColor DarkGray
Write-Host "  MCP servers are not touched -- remove those with 'claude mcp remove'." -ForegroundColor DarkGray
Write-Host ""
