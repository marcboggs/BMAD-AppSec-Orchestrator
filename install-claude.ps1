<#
.SYNOPSIS
    Installs the Security Agent Suite for Claude Code (user-level).
.DESCRIPTION
    Copies .claude/agents, .claude/skills, and .claude/commands from this repo
    into ~/.claude/, so the 10 agents, 54 skills, and 19 slash commands are
    available in every Claude Code project, not just this one.

    Unlike the old Kiro installers, there is no dependency order to respect --
    Claude Code subagents can spawn any other subagent that exists in
    ~/.claude/agents/ (or the current project's .claude/agents/) at call time,
    so agents don't need their dependencies pre-installed.
#>

$ErrorActionPreference = "Stop"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome  = Join-Path $env:USERPROFILE ".claude"
. (Join-Path $ScriptDir "lib\preflight.ps1")

Write-Host ""
Write-Host "  ==========================================================" -ForegroundColor Magenta
Write-Host "   Security Agent Suite for Claude Code" -ForegroundColor Magenta
Write-Host "   10 agents / 54 skills / 19 commands (user-level)" -ForegroundColor Magenta
Write-Host "  ==========================================================" -ForegroundColor Magenta
Write-Host ""

Invoke-Preflight

$AgentsDst   = Join-Path $ClaudeHome "agents"
$SkillsDst   = Join-Path $ClaudeHome "skills"
$CommandsDst = Join-Path $ClaudeHome "commands"
New-Item -ItemType Directory -Force -Path $AgentsDst, $SkillsDst, $CommandsDst | Out-Null

Write-Host "  * Installing agents..." -ForegroundColor DarkGray
Copy-Item -Path (Join-Path $ScriptDir ".claude\agents\*") -Destination $AgentsDst -Recurse -Force
Write-Host "  [OK] 10 agents  -> ~\.claude\agents\ (incl. resources\ templates)" -ForegroundColor Green

Write-Host "  * Installing skills..." -ForegroundColor DarkGray
Copy-Item -Path (Join-Path $ScriptDir ".claude\skills\*") -Destination $SkillsDst -Recurse -Force
$skillCount = (Get-ChildItem -Path $SkillsDst -Directory).Count
Write-Host "  [OK] Skills     -> ~\.claude\skills\ ($skillCount folders)" -ForegroundColor Green

Write-Host "  * Installing commands..." -ForegroundColor DarkGray
Copy-Item -Path (Join-Path $ScriptDir ".claude\commands\*") -Destination $CommandsDst -Recurse -Force
$cmdCount = (Get-ChildItem -Path $CommandsDst -Filter "*.md").Count
Write-Host "  [OK] Commands   -> ~\.claude\commands\ ($cmdCount files)" -ForegroundColor Green

Write-Host ""
Write-Host "  MCP servers (burp/playwright/semgrep) are project-scoped, not copied here." -ForegroundColor Yellow
Write-Host "  Run Claude Code from this repo to pick up its .mcp.json, or run:" -ForegroundColor DarkGray
Write-Host "    claude mcp add playwright -- npx -y @playwright/mcp@latest" -ForegroundColor DarkGray
Write-Host "    claude mcp add semgrep -- uvx semgrep-mcp" -ForegroundColor DarkGray
Write-Host "    (see .mcp.json in this repo for the burp entry to fill in)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ==========================================================" -ForegroundColor DarkGreen
Write-Host "  [OK] Installed. Start Claude Code and try:" -ForegroundColor Green
Write-Host "       /engage ./my-app  (full engagement, main session)" -ForegroundColor Green
Write-Host "       Agent tool -> subagent_type: secreview (one agent)" -ForegroundColor Green
Write-Host "  ==========================================================" -ForegroundColor DarkGreen
Write-Host ""
