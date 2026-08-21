<#
.SYNOPSIS
    Installs the compliance Kiro agent.
.DESCRIPTION
    REQUIRES: secreview, threat-model (reads findings from both).
#>
$ErrorActionPreference = "Stop"
$AgentName = "compliance"; $AgentLabel = "Compliance"; $AgentDesc = "Regulatory framework mapper"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Header { Write-Host "`n  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan; Write-Host "  │   📜  $AgentLabel — $AgentDesc           │" -ForegroundColor DarkCyan; Write-Host "  └────────────────────────────────────────────────────────┘`n" -ForegroundColor DarkCyan }
function Write-Step($m) { Write-Host "  ● " -NoNewline -ForegroundColor DarkGray; Write-Host $m }
function Write-Ok($m) { Write-Host "  ✓ " -NoNewline -ForegroundColor Green; Write-Host $m }
function Write-Warn($m) { Write-Host "  ⚠ " -NoNewline -ForegroundColor Yellow; Write-Host $m }
function Write-Fail($m) { Write-Host "  ✗ " -NoNewline -ForegroundColor Red; Write-Host $m }
function Write-Info($m) { Write-Host "  ℹ " -NoNewline -ForegroundColor Cyan; Write-Host $m -ForegroundColor DarkGray }
function Write-Footer { Write-Host "`n  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkGreen; Write-Host "  │  ✓  $AgentLabel installed successfully                   │" -ForegroundColor Green; Write-Host "  └────────────────────────────────────────────────────────┘" -ForegroundColor DarkGreen; Write-Host "  Run: " -NoNewline -ForegroundColor DarkGray; Write-Host "/agent $AgentName`n" -ForegroundColor Yellow }

Write-Header
Write-Step "Checking dependencies..."
Write-Host ""

# Dependency 1: secreview (MANDATORY)
$dep1 = Join-Path $KiroAgentsDir "secreview.json"
if (Test-Path $dep1) { Write-Ok "secreview is installed" }
else {
    Write-Warn "secreview is required but not installed"
    $inst = Join-Path (Join-Path (Split-Path $ScriptDir) "secreview") "install.ps1"
    if (Test-Path $inst) { Write-Host "  → Installing secreview..." -ForegroundColor Cyan; & $inst }
    else { Write-Fail "Cannot find secreview installer. Install it first."; exit 1 }
}

# Dependency 2: threat-model (MANDATORY)
$dep2 = Join-Path $KiroAgentsDir "threat-model.json"
if (Test-Path $dep2) { Write-Ok "threat-model is installed" }
else {
    Write-Warn "threat-model is required but not installed"
    $inst = Join-Path (Join-Path (Split-Path $ScriptDir) "threat-model") "install.ps1"
    if (Test-Path $inst) { Write-Host "  → Installing threat-model..." -ForegroundColor Cyan; & $inst }
    else { Write-Fail "Cannot find threat-model installer. Install it first."; exit 1 }
}
Write-Host ""

if (-not (Test-Path $KiroAgentsDir)) { New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null }
if (-not (Test-Path $ResourcesDir)) { New-Item -ItemType Directory -Path $ResourcesDir -Force | Out-Null }

Write-Step "Installing agent files..."
Copy-Item (Join-Path $ScriptDir "$AgentName.json") (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Ok "Config  → ~\.kiro\agents\$AgentName.json"
Copy-Item (Join-Path $ScriptDir "prompt.md") (Join-Path $ResourcesDir "prompt.md") -Force
Write-Ok "Prompt  → ~\.kiro\agents\$AgentName-resources\prompt.md"

Write-Footer
