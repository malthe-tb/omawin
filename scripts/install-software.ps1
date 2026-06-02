[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $SkipApps,
    [switch] $SkipWindowManagement,
    [switch] $SkipTerminal,
    [switch] $SkipFonts,
    [switch] $SkipCursors,
    [switch] $SkipTackyBorders,
    [switch] $SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$appPackages = @(
    @{ Name = 'Git'; Id = 'Git.Git' },
    @{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell' },
    @{ Name = 'Visual Studio Code'; Id = 'Microsoft.VisualStudioCode' },
    @{ Name = 'Zen Browser'; Id = 'Zen-Team.Zen-Browser' },
    @{ Name = 'Flow Launcher'; Id = 'Flow-Launcher.Flow-Launcher' },
    @{ Name = 'Everything'; Id = 'voidtools.Everything' },
    @{ Name = 'Docker Desktop'; Id = 'Docker.DockerDesktop' },
    @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' }
)

$windowPackages = @(
    @{ Name = 'komorebi'; Id = 'LGUG2Z.komorebi' },
    @{ Name = 'masir'; Id = 'LGUG2Z.masir' },
    @{ Name = 'whkd'; Id = 'LGUG2Z.whkd' }
)

$terminalPackages = @(
    @{ Name = 'Starship'; Id = 'Starship.Starship' },
    @{ Name = 'fzf'; Id = 'junegunn.fzf' },
    @{ Name = 'zoxide'; Id = 'ajeetdsouza.zoxide' },
    @{ Name = 'bat'; Id = 'sharkdp.bat' },
    @{ Name = 'eza'; Id = 'eza-community.eza' },
    @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' },
    @{ Name = 'fd'; Id = 'sharkdp.fd' },
    @{ Name = 'delta'; Id = 'dandavison.delta' },
    @{ Name = 'mise'; Id = 'jdx.mise' },
    @{ Name = 'lazygit'; Id = 'JesseDuffield.lazygit' },
    @{ Name = 'Neovim'; Id = 'Neovim.Neovim' }
)

function Test-Command {
    param([string] $Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-WingetPackageInstalled {
    param([string] $Id)

    $output = & winget list --id $Id --exact --source winget --disable-interactivity 2>$null
    return ($LASTEXITCODE -eq 0 -and ($output -match [regex]::Escape($Id)))
}

function Install-WingetPackage {
    param(
        [string] $Name,
        [string] $Id
    )

    if (-not (Test-Command 'winget')) {
        throw 'winget is required but was not found on PATH. Install App Installer from the Microsoft Store, then rerun this script.'
    }

    if (Test-WingetPackageInstalled -Id $Id) {
        Write-Host "Already installed: $Name ($Id)"
        return
    }

    $arguments = @(
        'install',
        '--id', $Id,
        '--exact',
        '--source', 'winget',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
    )

    if ($WhatIf) {
        Write-Host "Would install: $Name ($Id)"
        Write-Host "winget $($arguments -join ' ')"
        return
    }

    Write-Host "Installing: $Name ($Id)"
    & winget @arguments

    if ($LASTEXITCODE -ne 0) {
        throw "winget failed while installing $Name ($Id). Exit code: $LASTEXITCODE"
    }
}

function Add-UserPath {
    param([string] $Path)

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $paths = @()

    if ($currentPath) {
        $paths = $currentPath -split ';' | Where-Object { $_ }
    }

    if ($paths -contains $Path) {
        Write-Host "PATH already contains: $Path"
        return
    }

    if ($WhatIf) {
        Write-Host "Would add to user PATH: $Path"
        return
    }

    $newPath = ($paths + $Path) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = $env:Path + ';' + $Path
    Write-Host "Added to user PATH: $Path"
}

function Install-TackyBorders {
    $installDir = Join-Path $env:LOCALAPPDATA 'Programs\tacky-borders'
    $target = Join-Path $installDir 'tacky-borders.exe'

    if (Test-Path -LiteralPath $target -PathType Leaf) {
        Write-Host "Already installed: tacky-borders ($target)"
        Add-UserPath -Path $installDir
        return
    }

    $releaseUri = 'https://api.github.com/repos/lukeyou05/tacky-borders/releases/latest'

    if ($WhatIf) {
        Write-Host "Would download latest tacky-borders release from: $releaseUri"
        Write-Host "Would install to: $target"
        Write-Host "Would add to user PATH: $installDir"
        return
    }

    Write-Host 'Installing: tacky-borders'
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null

    $release = Invoke-RestMethod -Uri $releaseUri -Headers @{ 'User-Agent' = 'dotfiles-bootstrap' }
    $asset = $release.assets |
        Where-Object { $_.name -match '^tacky-borders.*\.(exe|zip)$' } |
        Sort-Object { if ($_.name -like '*.zip') { 0 } else { 1 } } |
        Select-Object -First 1

    if (-not $asset) {
        throw 'Could not find a tacky-borders .exe or .zip asset in the latest GitHub release.'
    }

    if ($asset.name -like '*.exe') {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $target -UseBasicParsing
    } else {
        $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $zipPath = Join-Path $tempRoot $asset.name
        $extractPath = Join-Path $tempRoot 'extract'

        try {
            New-Item -ItemType Directory -Force -Path $tempRoot, $extractPath | Out-Null
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
            Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

            $executable = Get-ChildItem -LiteralPath $extractPath -Recurse -File |
                Where-Object { $_.Name -eq 'tacky-borders.exe' } |
                Select-Object -First 1

            if (-not $executable) {
                throw "Could not find tacky-borders.exe inside release asset: $($asset.name)"
            }

            Copy-Item -LiteralPath $executable.FullName -Destination $target -Force
        } finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
            }
        }
    }

    Add-UserPath -Path $installDir
    Write-Host "Installed: tacky-borders ($target)"
}

function Install-NerdFont {
    $fontName = 'CaskaydiaMono Nerd Font'
    $releaseUri = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip'
    $fontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $fontsRegistryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    $fontRegistry = Get-ItemProperty -Path $fontsRegistryPath -ErrorAction SilentlyContinue
    $existingFont = $null

    if ($fontRegistry) {
        $existingFont = $fontRegistry |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like "$fontName*" -or $_.Name -like 'CaskaydiaMonoNerdFont*' } |
            Select-Object -First 1
    }

    if ($existingFont) {
        Write-Host "Already installed: $fontName"
        return
    }

    if ($WhatIf) {
        Write-Host "Would download latest $fontName release from: $releaseUri"
        Write-Host "Would install fonts to: $fontsDir"
        Write-Host "Would register fonts under: $fontsRegistryPath"
        return
    }

    Write-Host "Installing: $fontName"

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    $zipPath = Join-Path $tempRoot 'CascadiaMono.zip'
    $extractPath = Join-Path $tempRoot 'extract'

    try {
        New-Item -ItemType Directory -Force -Path $tempRoot, $extractPath, $fontsDir | Out-Null
        New-Item -Path $fontsRegistryPath -Force | Out-Null
        Invoke-WebRequest -Uri $releaseUri -OutFile $zipPath -UseBasicParsing
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

        $fontFiles = Get-ChildItem -LiteralPath $extractPath -Recurse -File |
            Where-Object { $_.Extension -in '.ttf', '.otf' }

        if (-not $fontFiles) {
            throw "Could not find font files inside $releaseUri"
        }

        foreach ($fontFile in $fontFiles) {
            $target = Join-Path $fontsDir $fontFile.Name
            Copy-Item -LiteralPath $fontFile.FullName -Destination $target -Force

            $fontType = if ($fontFile.Extension -eq '.otf') { 'OpenType' } else { 'TrueType' }
            $registryName = "$($fontFile.BaseName) ($fontType)"
            New-ItemProperty -Path $fontsRegistryPath -Name $registryName -Value $fontFile.Name -PropertyType String -Force | Out-Null
        }

        if (-not ('FontChangeNotifier' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class FontChangeNotifier
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult);
}
'@
        }
        $result = [UIntPtr]::Zero
        [FontChangeNotifier]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [UIntPtr]::Zero, $null, 0x0002, 1000, [ref]$result) | Out-Null

        Write-Host "Installed: $fontName"
    } finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}

function Install-VSCodeExtensions {
    if ($SkipVSCodeExtensions) {
        Write-Host 'Skipped VS Code extensions.'
        return
    }

    $extensionsPath = Join-Path $repoRoot 'config\vscode\extensions.txt'

    if (-not (Test-Path -LiteralPath $extensionsPath -PathType Leaf)) {
        Write-Host "Skipped VS Code extensions: source not found ($extensionsPath)"
        return
    }

    if (-not (Test-Command 'code')) {
        Write-Host 'Skipped VS Code extensions: code command not found on PATH. Open a new shell after installing VS Code, then rerun this script.'
        return
    }

    $extensions = Get-Content -Path $extensionsPath | Where-Object { $_ -and -not $_.StartsWith('#') }

    foreach ($extension in $extensions) {
        if ($WhatIf) {
            Write-Host "Would install VS Code extension: $extension"
            continue
        }

        Write-Host "Installing VS Code extension: $extension"
        & code --install-extension $extension
    }
}

function Install-BibataCursor {
    if ($SkipCursors) {
        Write-Host 'Skipped cursor theme.'
        return
    }

    & (Join-Path $repoRoot 'scripts\install-bibata-cursor.ps1') -WhatIf:$WhatIf
}

if (-not $SkipApps) {
    foreach ($package in $appPackages) {
        Install-WingetPackage -Name $package.Name -Id $package.Id
    }
}

if (-not $SkipWindowManagement) {
    foreach ($package in $windowPackages) {
        Install-WingetPackage -Name $package.Name -Id $package.Id
    }

    if (-not $SkipTackyBorders) {
        Install-TackyBorders
    }
}

if (-not $SkipTerminal) {
    foreach ($package in $terminalPackages) {
        Install-WingetPackage -Name $package.Name -Id $package.Id
    }

    if (-not $SkipFonts) {
        Install-NerdFont
    }
}

Install-BibataCursor
Install-VSCodeExtensions

Write-Host 'Software install script complete.'
