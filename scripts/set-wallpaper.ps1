[CmdletBinding()]
param(
    [string] $WallpaperPath,
    [string] $LockScreenPath,
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string] $Style = 'Fill',
    [switch] $SkipLockScreen,
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$defaultWallpaperPath = Join-Path $repoRoot 'assets\wallpapers\dr15.jpg'
$assetRoot = Join-Path $env:LOCALAPPDATA 'Dotfiles\Wallpapers'

if (-not $WallpaperPath) {
    $WallpaperPath = $defaultWallpaperPath
}

if (-not $LockScreenPath) {
    $LockScreenPath = $WallpaperPath
}

function Resolve-ImagePath {
    param(
        [string] $Path,
        [string] $Name
    )

    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "$Name image not found: $resolved"
    }

    $extension = [IO.Path]::GetExtension($resolved).ToLowerInvariant()
    if ($extension -notin '.jpg', '.jpeg', '.png', '.bmp') {
        throw "$Name image must be a .jpg, .jpeg, .png, or .bmp file: $resolved"
    }

    return $resolved
}

function Copy-WallpaperAsset {
    param(
        [string] $Source,
        [string] $Name
    )

    $extension = [IO.Path]::GetExtension($Source)
    $target = Join-Path $assetRoot "$Name$extension"

    if ($WhatIf) {
        Write-Host "Would copy image: $Source -> $target"
        return $target
    }

    New-Item -ItemType Directory -Force -Path $assetRoot | Out-Null
    Copy-Item -LiteralPath $Source -Destination $target -Force
    return $target
}

function Get-WallpaperStyleValues {
    param([string] $Style)

    switch ($Style) {
        'Fill' { return @{ WallpaperStyle = '10'; TileWallpaper = '0' } }
        'Fit' { return @{ WallpaperStyle = '6'; TileWallpaper = '0' } }
        'Stretch' { return @{ WallpaperStyle = '2'; TileWallpaper = '0' } }
        'Tile' { return @{ WallpaperStyle = '0'; TileWallpaper = '1' } }
        'Center' { return @{ WallpaperStyle = '0'; TileWallpaper = '0' } }
        'Span' { return @{ WallpaperStyle = '22'; TileWallpaper = '0' } }
    }
}

function Set-DesktopWallpaper {
    param([string] $Path)

    $desktopKey = 'HKCU:\Control Panel\Desktop'
    $styleValues = Get-WallpaperStyleValues -Style $Style

    if ($WhatIf) {
        Write-Host "Would set desktop wallpaper: $Path"
        Write-Host "Would set wallpaper style: $Style"
        return
    }

    Set-ItemProperty -Path $desktopKey -Name Wallpaper -Value $Path
    Set-ItemProperty -Path $desktopKey -Name WallpaperStyle -Value $styleValues.WallpaperStyle
    Set-ItemProperty -Path $desktopKey -Name TileWallpaper -Value $styleValues.TileWallpaper

    if (-not ('DesktopWallpaperApi' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class DesktopWallpaperApi
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool SystemParametersInfo(
        uint uiAction,
        uint uiParam,
        string pvParam,
        uint fWinIni);
}
'@
    }

    $updated = [DesktopWallpaperApi]::SystemParametersInfo(0x0014, 0, $Path, 0x0001 -bor 0x0002)
    if (-not $updated) {
        throw 'Windows did not accept the desktop wallpaper update.'
    }

    Write-Host "Set desktop wallpaper: $Path"
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-LockScreenWallpaper {
    param([string] $Path)

    $cspKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'

    if ($WhatIf) {
        Write-Host "Would set lock screen image: $Path"
        Write-Host "Would write lock screen policy keys under: $cspKey"
        Write-Host "Would write fallback policy key under: $policyKey"
        return
    }

    if (-not (Test-IsAdministrator)) {
        Write-Warning 'Skipped lock screen wallpaper: administrator rights are required to write HKLM personalization policy keys.'
        return
    }

    New-Item -Path $cspKey -Force | Out-Null
    New-ItemProperty -Path $cspKey -Name LockScreenImagePath -Value $Path -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $cspKey -Name LockScreenImageUrl -Value $Path -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $cspKey -Name LockScreenImageStatus -Value 1 -PropertyType DWord -Force | Out-Null

    New-Item -Path $policyKey -Force | Out-Null
    New-ItemProperty -Path $policyKey -Name LockScreenImage -Value $Path -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $policyKey -Name NoLockScreenSlideshow -Value 1 -PropertyType DWord -Force | Out-Null

    Write-Host "Set lock screen image policy: $Path"
}

$wallpaperSource = Resolve-ImagePath -Path $WallpaperPath -Name 'Wallpaper'
$lockScreenSource = Resolve-ImagePath -Path $LockScreenPath -Name 'Lock screen'
$wallpaperTarget = Copy-WallpaperAsset -Source $wallpaperSource -Name 'wallpaper'
$lockScreenTarget = Copy-WallpaperAsset -Source $lockScreenSource -Name 'lock-screen'

Set-DesktopWallpaper -Path $wallpaperTarget

if ($SkipLockScreen) {
    Write-Host 'Skipped lock screen wallpaper.'
} else {
    Set-LockScreenWallpaper -Path $lockScreenTarget
}
