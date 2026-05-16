[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$taskName = 'Dotfiles Desktop Startup'
$taskPath = '\Dotfiles\'

$existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if (-not $existingTask) {
    Write-Host "Scheduled task not found: $taskPath$taskName"
    exit 0
}

Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false

Write-Host "Unregistered scheduled task: $taskPath$taskName"
