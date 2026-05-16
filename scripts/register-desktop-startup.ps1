[CmdletBinding()]
param(
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$startupScript = Join-Path $PSScriptRoot 'start-desktop.ps1'
$taskName = 'Dotfiles Desktop Startup'
$taskPath = '\Dotfiles\'
$powershell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startupScript`""

if (-not (Test-Path -Path $startupScript)) {
    throw "Startup script not found: $startupScript"
}

$existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host "Scheduled task already exists: $taskPath$taskName"
    Write-Host 'Re-run with -Force to replace it.'
    exit 0
}

$action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments -WorkingDirectory $repoRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -InputObject $task -Force:$Force | Out-Null

Write-Host "Registered scheduled task: $taskPath$taskName"
Write-Host "Target script: $startupScript"
Write-Host 'You can test it now with:'
Write-Host "Start-ScheduledTask -TaskPath '$taskPath' -TaskName '$taskName'"
