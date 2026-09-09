# ─────────────────────────────────────────────────────────────────────────────
# preflight.ps1 — dot-sourced by the top-level PowerShell installers to check
# runtime prerequisites for the Security Agent Suite.
#
# These tools are NOT needed to copy files into place — they are needed when the
# agents run (the MCP servers and scanners). A missing tool is a WARNING, never
# a hard failure: the install still completes and the user is told what to get.
#
#   . "$ScriptDir\lib\preflight.ps1"
#   Invoke-Preflight
# ─────────────────────────────────────────────────────────────────────────────

function Test-ToolPresent {
    param([string]$Label, [string]$Command, [string]$Why, [string]$Hint)
    $found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "  [OK] $Label" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  [!]  $Label -- not found" -ForegroundColor Yellow
        Write-Host "       needed for: $Why" -ForegroundColor DarkGray
        Write-Host "       install:    $Hint" -ForegroundColor DarkGray
        return $false
    }
}

function Invoke-Preflight {
    Write-Host "  Checking runtime prerequisites..." -ForegroundColor Cyan
    Write-Host ""
    $missing = 0

    if (-not (Test-ToolPresent "node / npx" "npx" `
        "playwright MCP (browser-driven testing)" `
        "https://nodejs.org")) { $missing++ }

    if (-not (Test-ToolPresent "uv / uvx" "uvx" `
        "semgrep MCP (SAST via secreview/bughunter)" `
        "https://docs.astral.sh/uv/  or  'irm https://astral.sh/uv/install.ps1 | iex'")) { $missing++ }

    if (-not (Test-ToolPresent "semgrep" "semgrep" `
        "semgrep-scan skill / direct SAST (optional -- uvx can supply it)" `
        "'uv tool install semgrep'  or  'pipx install semgrep'")) { $missing++ }

    if (-not (Test-ToolPresent "git" "git" `
        "source-code recon skills (optional)" `
        "https://git-scm.com/download/win")) { $missing++ }

    Write-Host ""
    if ($missing -eq 0) {
        Write-Host "  All prerequisites present." -ForegroundColor Green
    } else {
        Write-Host "  $missing prerequisite(s) missing. Install continues -- these are only" -ForegroundColor Yellow
        Write-Host "  needed when the agents run. Install the above when you need them." -ForegroundColor DarkGray
    }
    Write-Host ""
}
