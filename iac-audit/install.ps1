<#
.SYNOPSIS
    Installs the iac-audit Kiro agent.
.DESCRIPTION
    IaC Audit is standalone — no agent dependencies.
#>
$ErrorActionPreference = "Stop"
$AgentName = "iac-audit"; $AgentLabel = "IaC Audit"; $AgentDesc = "Infrastructure-as-Code security auditor"
$KiroAgentsDir = Join-Path (Join-Path $env:USERPROFILE ".kiro") "agents"
$ResourcesDir = Join-Path $KiroAgentsDir "$AgentName-resources"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Header { Write-Host "`n  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan; Write-Host "  │   🏗️  $AgentLabel — $AgentDesc   │" -ForegroundColor DarkCyan; Write-Host "  └────────────────────────────────────────────────────────┘`n" -ForegroundColor DarkCyan }
function Write-Step($m) { Write-Host "  ● " -NoNewline -ForegroundColor DarkGray; Write-Host $m }
function Write-Ok($m) { Write-Host "  ✓ " -NoNewline -ForegroundColor Green; Write-Host $m }
function Write-Info($m) { Write-Host "  ℹ " -NoNewline -ForegroundColor Cyan; Write-Host $m -ForegroundColor DarkGray }
function Write-Footer { Write-Host "`n  ┌────────────────────────────────────────────────────────┐" -ForegroundColor DarkGreen; Write-Host "  │  ✓  $AgentLabel installed successfully                       │" -ForegroundColor Green; Write-Host "  └────────────────────────────────────────────────────────┘" -ForegroundColor DarkGreen; Write-Host "  Run: " -NoNewline -ForegroundColor DarkGray; Write-Host "/agent $AgentName`n" -ForegroundColor Yellow }

Write-Header
Write-Step "Checking prerequisites..."
Write-Info "No agent dependencies (standalone scanner)"
Write-Host ""

if (-not (Test-Path $KiroAgentsDir)) { New-Item -ItemType Directory -Path $KiroAgentsDir -Force | Out-Null }
if (-not (Test-Path $ResourcesDir)) { New-Item -ItemType Directory -Path $ResourcesDir -Force | Out-Null }

Write-Step "Installing agent files..."
Copy-Item (Join-Path $ScriptDir "$AgentName.json") (Join-Path $KiroAgentsDir "$AgentName.json") -Force
Write-Ok "Config  → ~\.kiro\agents\$AgentName.json"
Copy-Item (Join-Path $ScriptDir "prompt.md") (Join-Path $ResourcesDir "prompt.md") -Force
Write-Ok "Prompt  → ~\.kiro\agents\$AgentName-resources\prompt.md"

Write-Footer
