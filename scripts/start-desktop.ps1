[CmdletBinding()]
param(
    [switch] $Restart,
    [int] $StartupDelaySeconds = 8,
    [int] $HealthCheckSeconds = 20
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $repoRoot 'var\logs'
$logFile = Join-Path $logDir 'desktop-startup.log'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log {
    param([string] $Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function Test-Command {
    param([string] $Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Resolve-CommandPath {
    param(
        [string] $Command,
        [string[]] $FallbackPaths = @()
    )

    $resolved = Get-Command $Command -ErrorAction SilentlyContinue
    if ($resolved) {
        return $resolved.Source
    }

    foreach ($fallbackPath in $FallbackPaths) {
        if (Test-Path -LiteralPath $fallbackPath -PathType Leaf) {
            return $fallbackPath
        }
    }

    return $null
}

function Add-PathEntry {
    param([string] $Path)

    if ((Test-Path -LiteralPath $Path -PathType Container) -and
        (($env:Path -split ';') -notcontains $Path)) {
        $env:Path = "$Path;$env:Path"
    }
}

function Start-Command {
    param(
        [string] $Name,
        [string] $Command,
        [string[]] $Arguments = @(),
        [string[]] $FallbackPaths = @(),
        [int] $DelaySeconds = 0,
        [switch] $Wait
    )

    $commandPath = Resolve-CommandPath -Command $Command -FallbackPaths $FallbackPaths

    if (-not $commandPath) {
        Write-Log "SKIP: $Name ($Command not found on PATH)"
        return
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }

    try {
        Write-Log "START: $Name"

        if ($Wait) {
            $output = & $commandPath @Arguments 2>&1
            foreach ($line in $output) {
                Write-Log "${Name}: $line"
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Log "ERROR: $Name exited with code $LASTEXITCODE"
            }
        }
        elseif ($Arguments -and $Arguments.Count -gt 0) {
            Start-Process -WindowStyle Hidden -FilePath $commandPath -ArgumentList $Arguments
        }
        else {
            Start-Process -WindowStyle Hidden -FilePath $commandPath
        }
    }
    catch {
        Write-Log "ERROR: Failed to start $Name - $($_.Exception.Message)"
    }
}

function Test-ProcessRunning {
    param([string] $Name)

    $null -ne (Get-Process -Name $Name -ErrorAction SilentlyContinue)
}

function Wait-ProcessRunning {
    param(
        [string] $Name,
        [int] $TimeoutSeconds = 10
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    do {
        if (Test-ProcessRunning -Name $Name) {
            Write-Log "OK: $Name is running"
            return $true
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    Write-Log "WARN: $Name is not running after $TimeoutSeconds seconds"
    return $false
}

Write-Log 'Desktop startup begin'

$Env:KOMOREBI_CONFIG_HOME = Join-Path $HOME '.config\komorebi'
$komorebicPath = Join-Path $env:ProgramFiles 'komorebi\bin\komorebic.exe'
$komorebiBin = Split-Path -Parent $komorebicPath
$tackyBordersDir = Join-Path $env:LOCALAPPDATA 'Programs\tacky-borders'
$tackyBordersPath = Join-Path $env:LOCALAPPDATA 'Programs\tacky-borders\tacky-borders.exe'

Add-PathEntry -Path $komorebiBin
Add-PathEntry -Path $tackyBordersDir

if ($StartupDelaySeconds -gt 0) {
    Write-Log "WAIT: delaying startup by $StartupDelaySeconds seconds"
    Start-Sleep -Seconds $StartupDelaySeconds
}

if ($Restart) {
    if (Test-Command 'komorebic') {
        Write-Log 'STOP: komorebi'
        & komorebic stop 2>&1 | ForEach-Object { Write-Log "komorebic: $_" }
    }
}

Get-Process -Name 'tacky-borders' -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Command -Name 'komorebi' -Command 'komorebic' -Arguments @('start', '--whkd', '--masir', '--bar') -FallbackPaths @($komorebicPath) -Wait
Start-Command -Name 'tacky-borders' -Command 'tacky-borders' -FallbackPaths @($tackyBordersPath) -DelaySeconds 5

Wait-ProcessRunning -Name 'komorebi' -TimeoutSeconds $HealthCheckSeconds | Out-Null
Wait-ProcessRunning -Name 'whkd' -TimeoutSeconds 5 | Out-Null
Wait-ProcessRunning -Name 'komorebi-bar' -TimeoutSeconds 5 | Out-Null
Wait-ProcessRunning -Name 'masir' -TimeoutSeconds 5 | Out-Null
Wait-ProcessRunning -Name 'tacky-borders' -TimeoutSeconds 5 | Out-Null

Write-Log 'Desktop startup complete'
