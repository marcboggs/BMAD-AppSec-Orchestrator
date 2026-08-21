<#
.SYNOPSIS
    Installs the threat-model Kiro agent.
.DESCRIPTION
    STRIDE-based threat modeling with Markdown + HTML reports.
    REQUIRES: secreview (spawned as subagent for SAST/SCA findings).
#>

$ErrorActionPreference = "Stop"

# ─── Config ────────────────────────────────────────────────────────────────────
$AgentName     = "threat-model"
$AgentLabel    = "Threat Model"
$AgentDesc     = "STRIDE threat modeling"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir  = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── TUI Helpers ───────────────────────────────────────────────────────────────
function Write-Header {
    $border = "─" * 52
    Write-Host ""
    Write-Host "  ┌$border┐" -ForegroundColor DarkCyan
    Write-Host "  │                                                    │" -ForegroundColor DarkCyan
    Write-Host "  │   🛡️  $AgentLabel — $AgentDesc" -ForegroundColor DarkCyan -NoNewline
    $pad = 52 - 8 - $AgentLabel.Length - $AgentDesc.Length
    Write-Host (" " * $pad) -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │                                                    │" -ForegroundColor DarkCyan
    Write-Host "  └$border┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step($msg) {
    Write-Host "  ● " -NoNewline -ForegroundColor DarkGray
    Write-Host "$msg" -ForegroundColor White
}

function Write-Success($msg) {
    Write-Host "  ✓ " -NoNewline -ForegroundColor Green
    Write-Host "$msg" -ForegroundColor White
}

function Write-Warn($msg) {
    Write-Host "  ⚠ " -NoNewline -ForegroundColor Yellow
    Write-Host "$msg" -ForegroundColor White
}

function Write-Fail($msg) {
    Write-Host "  ✗ " -NoNewline -ForegroundColor Red
    Write-Host "$msg" -ForegroundColor White
}

function Write-Info($msg) {
    Write-Host "  ℹ " -NoNewline -ForegroundColor Cyan
    Write-Host "$msg" -ForegroundColor DarkGray
}

function Write-Footer {
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────┐" -ForegroundColor DarkGreen
    Write-Host "  │  ✓  $AgentLabel installed successfully" -ForegroundColor Green -NoNewline
    $pad = 52 - 4 - $AgentLabel.Length - " installed successfully".Length
    Write-Host (" " * $pad) -NoNewline
    Write-Host "│" -ForegroundColor DarkGreen
    Write-Host "  └──────────────────────────────────────────────────────┘" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "  Run: " -NoNewline -ForegroundColor DarkGray
    Write-Host "/agent $AgentName" -ForegroundColor Yellow
    Write-Host ""
}

# ─── Main ──────────────────────────────────────────────────────────────────────
Write-Header

# ─── Dependency: secreview (MANDATORY) ─────────────────────────────────────────
Write-Step "Checking dependencies..."
Write-Host ""

$SecreviewConfig = Join-Path $KiroAgentsDir "secreview.json"
if (Test-Path $SecreviewConfig) {
    Write-Success "secreview is installed"
} else {
    Write-Warn "secreview is required but not installed"
    Write-Info "Threat-model delegates SAST/SCA scanning to secreview"
    Write-Host ""

    $SecreviewInstaller = Join-Path (Join-Path (Split-Path $ScriptDir) "secreview") "install.ps1"
    if (Test-Path $SecreviewInstaller) {
        Write-Host "  → Installing secreview dependency..." -ForegroundColor Cyan
        Write-Host ""
        & $SecreviewInstaller
    } else {
        Write-Fail "Cannot find secreview installer"
        Write-Host ""
        Write-Host "  Install secreview first:" -ForegroundColor Red
        Write-Host "    .\secreview\install.ps1" -ForegroundColor DarkGray
        Write-Host ""
        exit 1
    }
}
Write-Host ""

# ─── Create directories ───────────────────────────────────────────────────────
Write-Step "Preparing directories..."
if (-not (Test-Path $KiroAgentsDir)) { New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null }
if (-not (Test-Path $ResourcesDir))  { New-Item -ItemType Directory -Path $ResourcesDir  -Force | Out-Null }

# ─── Install files ─────────────────────────────────────────────────────────────
Write-Step "Installing agent files..."
Copy-Item -Path (Join-Path $ScriptDir "$AgentName.json") -Destination (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Success "Config  → ~\.kiro\agents\$AgentName.json"

# Resources
Write-Step "Installing resources..."
$ResourcesSrc = Join-Path $ScriptDir "resources"
$ResourceFiles = Get-ChildItem -Path $ResourcesSrc -File
foreach ($file in $ResourceFiles) {
    Copy-Item -Path $file.FullName -Destination (Join-Path $ResourcesDir $file.Name) -Force
    Write-Success "$($file.Name)"
}

Write-Footer
