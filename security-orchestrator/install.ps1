$ErrorActionPreference = "Stop"
$AgentName = "security-orchestrator"; $AgentLabel = "Security Orchestrator"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── TUI Helpers ──────────────────────────────────────────────────────────────
function Write-Banner {
    $border = [string][char]0x2550
    $tl = [string][char]0x2554; $tr = [string][char]0x2557
    $bl = [string][char]0x255A; $br = [string][char]0x255D
    $vr = [string][char]0x2551
    $line = $border * 52
    Write-Host ""
    Write-Host "  $tl$line$tr" -ForegroundColor Cyan
    Write-Host "  $vr  " -ForegroundColor Cyan -NoNewline
    Write-Host "Security Orchestrator Installer" -ForegroundColor White -NoNewline
    Write-Host (" " * 19) -NoNewline
    Write-Host "$vr" -ForegroundColor Cyan
    Write-Host "  $vr  " -ForegroundColor Cyan -NoNewline
    Write-Host "Coordinates the 8-agent security suite" -ForegroundColor DarkGray -NoNewline
    Write-Host (" " * 12) -NoNewline
    Write-Host "$vr" -ForegroundColor Cyan
    Write-Host "  $bl$line$br" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Icon, [string]$Message)
    Write-Host "  $Icon " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host $Message -ForegroundColor White
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  [!!] " -NoNewline -ForegroundColor Red
    Write-Host $Message -ForegroundColor Red
}

# ── Main ─────────────────────────────────────────────────────────────────────
Write-Banner

# Verify source files exist
$JsonSource = Join-Path $ScriptDir "$AgentName.json"
$PromptSource = Join-Path $ScriptDir "prompt.md"

if (-not (Test-Path $JsonSource)) {
    Write-Fail "Missing $AgentName.json in script directory"
    exit 1
}
if (-not (Test-Path $PromptSource)) {
    Write-Fail "Missing prompt.md in script directory"
    exit 1
}

# Create directories
Write-Step ">>" "Creating agent directories..."
if (-not (Test-Path $KiroAgentsDir)) {
    New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null
}
if (-not (Test-Path $ResourcesDir)) {
    New-Item -ItemType Directory -Path $ResourcesDir -Force | Out-Null
}
Write-Success "Directories ready"

# Copy agent config
Write-Step ">>" "Installing agent config..."
$JsonDest = Join-Path $KiroAgentsDir "$AgentName.json"
Copy-Item -Path $JsonSource -Destination $JsonDest -Force
Write-Success "$AgentName.json installed"

# Copy prompt
Write-Step ">>" "Installing system prompt..."
$PromptDest = Join-Path $ResourcesDir "prompt.md"
Copy-Item -Path $PromptSource -Destination $PromptDest -Force
Write-Success "prompt.md installed"

# Verify installation
Write-Step ">>" "Verifying installation..."
$allGood = $true
if (-not (Test-Path $JsonDest)) { Write-Fail "Agent config not found"; $allGood = $false }
if (-not (Test-Path $PromptDest)) { Write-Fail "Prompt not found"; $allGood = $false }

if ($allGood) {
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Success "$AgentLabel installed successfully!"
    Write-Host ""
    Write-Host "  Usage:" -ForegroundColor DarkGray
    Write-Host "    kiro chat --agent $AgentName" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Fail "Installation incomplete — check errors above."
    exit 1
}
