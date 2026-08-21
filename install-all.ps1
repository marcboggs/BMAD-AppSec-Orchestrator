<#
.SYNOPSIS
    Installs the full Security Agent Suite for Kiro CLI (8 agents).
.DESCRIPTION
    Installs all agents in dependency order so each agent's deps are satisfied.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Banner {
    $border = "─" * 52
    Write-Host ""
    Write-Host "  ┌$border┐" -ForegroundColor Magenta
    Write-Host "  │                                                    │" -ForegroundColor Magenta
    Write-Host "  │     🔐  Security Agent Suite for Kiro CLI          │" -ForegroundColor Magenta
    Write-Host "  │                                                    │" -ForegroundColor Magenta
    Write-Host "  │     Installing 9 agents in dependency order        │" -ForegroundColor Magenta
    Write-Host "  │                                                    │" -ForegroundColor Magenta
    Write-Host "  │     Orchestrator: security-orchestrator            │" -ForegroundColor Magenta
    Write-Host "  │     Layer 1: secreview, iac-audit (no deps)        │" -ForegroundColor Magenta
    Write-Host "  │     Layer 2: bughunter, api-spec-review,           │" -ForegroundColor Magenta
    Write-Host "  │              supply-chain                          │" -ForegroundColor Magenta
    Write-Host "  │     Layer 3: threat-model                          │" -ForegroundColor Magenta
    Write-Host "  │     Layer 4: compliance, pentest-planner           │" -ForegroundColor Magenta
    Write-Host "  │                                                    │" -ForegroundColor Magenta
    Write-Host "  └$border┘" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Phase($num, $total, $name) {
    Write-Host ""
    Write-Host "  ── [$num/$total] $name " -ForegroundColor Cyan -NoNewline
    Write-Host ("─" * (40 - $name.Length)) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Summary {
    $border = "─" * 52
    Write-Host ""
    Write-Host "  ┌$border┐" -ForegroundColor DarkGreen
    Write-Host "  │                                                    │" -ForegroundColor DarkGreen
    Write-Host "  │  ✓  All 9 agents installed successfully!           │" -ForegroundColor Green
    Write-Host "  │                                                    │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent security-orchestrator → Start here!        │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent secreview       → SAST/SCA reviewer        │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent iac-audit       → IaC security scanner     │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent bughunter       → Red-team operator        │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent api-spec-review → API security             │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent supply-chain    → Dependency & CI/CD       │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent threat-model    → STRIDE modeling          │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent compliance      → Regulatory mapping       │" -ForegroundColor DarkGreen
    Write-Host "  │  /agent pentest-planner → Pentest plan generator   │" -ForegroundColor DarkGreen
    Write-Host "  │                                                    │" -ForegroundColor DarkGreen
    Write-Host "  └$border┘" -ForegroundColor DarkGreen
    Write-Host ""
}

Write-Banner

# Layer 0: Orchestrator (no dependencies)
Write-Phase 1 9 "Security Orchestrator"
& (Join-Path (Join-Path $ScriptDir "security-orchestrator") "install.ps1")

# Layer 1: No dependencies
Write-Phase 2 9 "SecReview (base)"
& (Join-Path (Join-Path $ScriptDir "secreview") "install.ps1")

Write-Phase 3 9 "IaC Audit (standalone)"
& (Join-Path (Join-Path $ScriptDir "iac-audit") "install.ps1")

# Layer 2: Depends on secreview
Write-Phase 4 9 "BugHunter"
& (Join-Path (Join-Path $ScriptDir "bughunter") "install.ps1")

Write-Phase 5 9 "API Spec Review"
& (Join-Path (Join-Path $ScriptDir "api-spec-review") "install.ps1")

Write-Phase 6 9 "Supply Chain"
& (Join-Path (Join-Path $ScriptDir "supply-chain") "install.ps1")

# Layer 3: Depends on secreview
Write-Phase 7 9 "Threat Model"
& (Join-Path (Join-Path $ScriptDir "threat-model") "install.ps1")

# Layer 4: Multiple deps
Write-Phase 8 9 "Compliance"
& (Join-Path (Join-Path $ScriptDir "compliance") "install.ps1")

Write-Phase 9 9 "Pentest Planner"
& (Join-Path (Join-Path $ScriptDir "pentest-planner") "install.ps1")

Write-Summary
