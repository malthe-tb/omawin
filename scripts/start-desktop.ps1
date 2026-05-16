[CmdletBinding()]
param(
    [switch] $Restart
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $repoRoot 'var\logs'
$logFile = Join-Path $logDir 'desktop-startup.log'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log {
    param([string] $Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$timestamp] $Message" | Tee-Object -FilePath $logFile -Append
}

function Test-Command {
    param([string] $Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Start-Command {
    param(
        [string] $Name,
        [string] $Command,
        [string[]] $Arguments = @(),
        [int] $DelaySeconds = 0
    )

    if (-not (Test-Command $Command)) {
        Write-Log "SKIP: $Name ($Command not found on PATH)"
        return
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }

    try {
        Write-Log "START: $Name"
        Start-Process -WindowStyle Hidden -FilePath $Command -ArgumentList $Arguments
    }
    catch {
        Write-Log "ERROR: Failed to start $Name - $($_.Exception.Message)"
    }
}

Write-Log 'Desktop startup begin'

if ($Restart) {
    if (Test-Command 'yasbc') {
        Write-Log 'STOP: YASB'
        & yasbc stop --silent 2>&1 | ForEach-Object { Write-Log "yasbc: $_" }
    }

    if (Test-Command 'komorebic') {
        Write-Log 'STOP: komorebi'
        & komorebic stop 2>&1 | ForEach-Object { Write-Log "komorebic: $_" }
    }

    Get-Process -Name 'tacky-borders' -ErrorAction SilentlyContinue | Stop-Process -Force
}

Start-Command -Name 'komorebi' -Command 'komorebic' -Arguments @('start', '--whkd', '--masir')
Start-Command -Name 'YASB' -Command 'yasbc' -Arguments @('start', '--silent') -DelaySeconds 2
Start-Command -Name 'tacky-borders' -Command 'tacky-borders' -DelaySeconds 1

Write-Log 'Desktop startup complete'
