#Requires -Version 5.1
<#
.SYNOPSIS
  Installs the qrme OpenCode skill.

.DESCRIPTION
  Copies skills\qrme to %USERPROFILE%\.config\opencode\skills\qrme
  and runs a smoke test that must produce a 1000x1000 PNG.

.PARAMETER Force
  Overwrite an existing qrme skill.

.PARAMETER Project
  Install into .\.opencode\skills instead of the global folder.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -Force
  .\install.ps1 -Project
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Project
)

$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'skills\qrme'
$destBase = if ($Project) {
    Join-Path (Get-Location).Path '.opencode\skills'
} else {
    Join-Path $HOME '.config\opencode\skills'
}
$dest = Join-Path $destBase 'qrme'

function Fail([string]$Message) {
    Write-Host "error: $Message" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $src 'SKILL.md')) -or
    -not (Test-Path (Join-Path $src 'scripts\make_qr.py'))) {
    Fail "skill files missing under $src"
}

# --- python check -----------------------------------------------------------
$python = $null
foreach ($candidate in @('python3', 'python', 'py')) {
    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    & $cmd.Source -c "import sys; raise SystemExit(0 if sys.version_info[0] == 3 else 1)" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $python = $cmd.Source
        break
    }
}

if (-not $python) {
    Fail 'Python 3 is required but was not found. Install it from https://python.org and re-run.'
}

# --- install ----------------------------------------------------------------
if (Test-Path $dest) {
    if (-not $Force) {
        Fail "$dest already exists (use -Force to overwrite)"
    }
    Remove-Item -Recurse -Force $dest
}

New-Item -ItemType Directory -Force -Path $destBase | Out-Null
Copy-Item -Recurse -Force $src $dest

# --- smoke test -------------------------------------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("qrme-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

try {
    Write-Host '==> testing QR generation'
    $out = & $python (Join-Path $dest 'scripts\make_qr.py') 'https://example.com' (Join-Path $tmp 'test.png') 2>&1
    if ($LASTEXITCODE -ne 0 -or -not ($out -match '1000x1000')) {
        Fail "smoke test failed: $out"
    }
    Write-Host "==> $($out -join ' ')"
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "Installed qrme -> $dest" -ForegroundColor Green
Write-Host 'Try in OpenCode:  @qrme https://example.com'
