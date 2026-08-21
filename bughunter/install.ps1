<#
.SYNOPSIS
    Installs the bughunter Kiro agent.
.DESCRIPTION
    Bug bounty / red-team operator with 51 skills and 14 commands.
    REQUIRES: secreview (spawned as subagent for SAST/SCA).
#>

$ErrorActionPreference = "Stop"

# ─── Config ────────────────────────────────────────────────────────────────────
$AgentName     = "bughunter"
$AgentLabel    = "BugHunter"
$AgentDesc     = "Bug bounty / red-team operator"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir  = Join-Path $KiroAgentsDir "$AgentName-resources"
$SkillsDir     = Join-Path (Join-Path (Join-Path $env:USERPROFILE ".kiro") "skills") $AgentName
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── TUI Helpers ───────────────────────────────────────────────────────────────
function Write-Header {
    $border = "─" * 52
    Write-Host ""
    Write-Host "  ┌$border┐" -ForegroundColor DarkCyan
    Write-Host "  │                                                    │" -ForegroundColor DarkCyan
    Write-Host "  │   🐛  $AgentLabel — $AgentDesc" -ForegroundColor DarkCyan -NoNewline
    $pad = 52 - 7 - $AgentLabel.Length - $AgentDesc.Length
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
    Write-Info "BugHunter spawns secreview for SAST/SCA scanning"
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
if (-not (Test-Path $SkillsDir))     { New-Item -ItemType Directory -Path $SkillsDir     -Force | Out-Null }

# ─── Install files ─────────────────────────────────────────────────────────────
Write-Step "Installing agent files..."
Copy-Item -Path (Join-Path $ScriptDir "$AgentName.json") -Destination (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Success "Config  → ~\.kiro\agents\$AgentName.json"

Copy-Item -Path (Join-Path $ScriptDir "prompt.md") -Destination (Join-Path $ResourcesDir "prompt.md") -Force
Write-Success "Prompt  → ~\.kiro\agents\$AgentName-resources\prompt.md"

# Skills
$SkillsSrc = Join-Path $ScriptDir "skills"
if (Test-Path $SkillsSrc) {
    Write-Step "Installing skills..."
    Copy-Item -Path "$SkillsSrc\*" -Destination $SkillsDir -Recurse -Force
    $skillCount = (Get-ChildItem -Path $SkillsDir -Directory).Count
    Write-Success "Skills  → ~\.kiro\skills\$AgentName\ ($skillCount folders)"
}

Write-Footer
