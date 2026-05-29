[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $SkipInstall,
    [switch] $SkipConfigs,
    [switch] $SkipStartup,
    [switch] $SkipFonts,
    [switch] $SkipCursors,
    [switch] $SkipWallpaper,
    [switch] $SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot

function Invoke-Step {
    param(
        [string] $Name,
        [scriptblock] $Action
    )

    Write-Host ""
    Write-Host "==> $Name"
    & $Action
}

if (-not $SkipInstall) {
    Invoke-Step -Name 'Install software' -Action {
        & (Join-Path $repoRoot 'scripts\install-software.ps1') `
            -WhatIf:$WhatIf `
            -SkipFonts:$SkipFonts `
            -SkipCursors:$SkipCursors `
            -SkipVSCodeExtensions:$SkipVSCodeExtensions
    }
}

if (-not $SkipConfigs) {
    Invoke-Step -Name 'Apply configs' -Action {
        & (Join-Path $repoRoot 'scripts\apply-configs.ps1') `
            -WhatIf:$WhatIf `
            -SkipVSCodeExtensions:$SkipVSCodeExtensions
    }
}

if (-not $SkipWallpaper) {
    Invoke-Step -Name 'Set wallpaper' -Action {
        & (Join-Path $repoRoot 'scripts\set-wallpaper.ps1') -WhatIf:$WhatIf
    }
}

if (-not $SkipStartup) {
    Invoke-Step -Name 'Register desktop startup task' -Action {
        if ($WhatIf) {
            Write-Host 'Would register scheduled task: \Dotfiles\Dotfiles Desktop Startup'
            return
        }

        & (Join-Path $repoRoot 'scripts\register-desktop-startup.ps1') -Force
    }
}

Write-Host ""
Write-Host 'Setup complete.'
