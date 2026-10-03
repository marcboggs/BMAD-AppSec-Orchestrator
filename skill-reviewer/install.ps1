<#
.SYNOPSIS
    Installs the skill-reviewer Kiro agent.
.DESCRIPTION
    Skill Reviewer is standalone — no agent dependencies. It ships a
    self-contained, dependency-free pre-filter (prefilter.py) and its steering
    resources. Python 3.8+ on PATH is optional (needed only to run the
    pre-filter; the agent works without it at reduced coverage).
#>
$ErrorActionPreference = "Stop"
$AgentName = "skill-reviewer"
$AgentLabel = "Skill Reviewer"
$AgentDesc = "Agent-skill & prompt trust reviewer"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Header {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │   🕵️  $AgentLabel — $AgentDesc   │" -ForegroundColor DarkCyan
    Write-Host "  └────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}
function Write-Step($m) { Write-Host "  ● " -NoNewline -ForegroundColor DarkGray; Write-Host $m }
function Write-Ok($m)   { Write-Host "  ✓ " -NoNewline -ForegroundColor Green; Write-Host $m }
function Write-Warn($m) { Write-Host "  ⚠ " -NoNewline -ForegroundColor Yellow; Write-Host $m }
function Write-Info($m) { Write-Host "  ℹ " -NoNewline -ForegroundColor Cyan; Write-Host $m -ForegroundColor DarkGray }
function Write-Footer {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkGreen
    Write-Host "  │  ✓  $AgentLabel installed successfully                       │" -ForegroundColor Green
    Write-Host "  └────────────────────────────────────────────────────────┘" -ForegroundColor DarkGreen
    Write-Host "  Run: " -NoNewline -ForegroundColor DarkGray
    Write-Host "/agent $AgentName" -ForegroundColor Yellow
    Write-Host ""
}

Write-Header
Write-Step "Checking prerequisites..."
Write-Info "No agent dependencies (standalone reviewer)"
$py = $null
foreach ($c in @("python", "python3", "py")) { if (Get-Command $c -ErrorAction SilentlyContinue) { $py = $c; break } }
if ($py) { Write-Info "Python detected ($py) — pre-filter is runnable" }
else { Write-Warn "Python 3.8+ not found on PATH — install it so the pre-filter can run (agent still works, reduced coverage)" }
Write-Host ""

if (-not (Test-Path $KiroAgentsDir)) { New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null }
if (-not (Test-Path $ResourcesDir)) { New-Item -ItemType Directory -Path $ResourcesDir -Force | Out-Null }

Write-Step "Installing agent files..."
Copy-Item (Join-Path $ScriptDir "$AgentName.json") (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Ok "Config    → ~\.kiro\agents\$AgentName.json"
Copy-Item (Join-Path $ScriptDir "prompt.md") (Join-Path $ResourcesDir "prompt.md") -Force
Write-Ok "Prompt    → ~\.kiro\agents\$AgentName-resources\prompt.md"

Write-Step "Installing resources (pre-filter + steering + hook logger)..."
Get-ChildItem (Join-Path $ScriptDir "resources") -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $ResourcesDir $_.Name) -Force
    Write-Ok "$($_.Name)  → ~\.kiro\agents\$AgentName-resources\$($_.Name)"
}
$LogsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

Write-Footer
