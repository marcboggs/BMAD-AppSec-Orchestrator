<#
.SYNOPSIS
    Installs the secreview Kiro agent.
.DESCRIPTION
    SecReview is the base agent — no dependencies.
    Performs SAST/SCA analysis and produces DAST-ready findings.
#>

$ErrorActionPreference = "Stop"

# ─── Config ────────────────────────────────────────────────────────────────────
$AgentName     = "secreview"
$AgentLabel    = "SecReview"
$AgentDesc     = "SAST/SCA code reviewer"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir  = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── TUI Helpers ───────────────────────────────────────────────────────────────
function Write-Header {
    $border = "─" * 52
    Write-Host ""
    Write-Host "  ┌$border┐" -ForegroundColor DarkCyan
    Write-Host "  │                                                    │" -ForegroundColor DarkCyan
    Write-Host "  │   🔒  $AgentLabel — $AgentDesc" -ForegroundColor DarkCyan -NoNewline
    $pad = 52 - 7 - $AgentLabel.Length - $AgentDesc.Length
    Write-Host (" " * $pad) -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │                                                    │" -ForegroundColor DarkCyan
    Write-Host "  └$border┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step($icon, $msg) {
    Write-Host "  $icon " -NoNewline -ForegroundColor DarkGray
    Write-Host "$msg" -ForegroundColor White
}

function Write-Success($msg) {
    Write-Host "  ✓ " -NoNewline -ForegroundColor Green
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

# No dependencies — secreview is the base agent
Write-Step "●" "Checking prerequisites..."
Write-Info "No agent dependencies (base agent)"
Write-Host ""

# Create directories
Write-Step "●" "Preparing directories..."
if (-not (Test-Path $KiroAgentsDir)) {
    New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null
}
if (-not (Test-Path $ResourcesDir)) {
    New-Item -ItemType Directory -Path $ResourcesDir -Force | Out-Null
}

# Install files
Write-Step "●" "Installing agent files..."
Copy-Item -Path (Join-Path $ScriptDir "$AgentName.json") -Destination (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Success "Config  → ~\.kiro\agents\$AgentName.json"

Copy-Item -Path (Join-Path $ScriptDir "prompt.md") -Destination (Join-Path $ResourcesDir "prompt.md") -Force
Write-Success "Prompt  → ~\.kiro\agents\$AgentName-resources\prompt.md"

Write-Footer
