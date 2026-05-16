[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $SkipApps,
    [switch] $SkipWindowManagement,
    [switch] $SkipTerminal,
    [switch] $SkipTackyBorders,
    [switch] $SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$appPackages = @(
    @{ Name = 'Git'; Id = 'Git.Git' },
    @{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell' },
    @{ Name = 'Visual Studio Code'; Id = 'Microsoft.VisualStudioCode' },
    @{ Name = 'Flow Launcher'; Id = 'Flow-Launcher.Flow-Launcher' },
    @{ Name = 'Everything'; Id = 'voidtools.Everything' },
    @{ Name = 'WezTerm'; Id = 'wez.wezterm' }
)

$windowPackages = @(
    @{ Name = 'komorebi'; Id = 'LGUG2Z.komorebi' },
    @{ Name = 'masir'; Id = 'LGUG2Z.masir' },
    @{ Name = 'whkd'; Id = 'LGUG2Z.whkd' },
    @{ Name = 'YASB'; Id = 'AmN.yasb' }
)

$terminalPackages = @(
    @{ Name = 'Starship'; Id = 'Starship.Starship' },
    @{ Name = 'fzf'; Id = 'junegunn.fzf' },
    @{ Name = 'zoxide'; Id = 'ajeetdsouza.zoxide' },
    @{ Name = 'bat'; Id = 'sharkdp.bat' },
    @{ Name = 'eza'; Id = 'eza-community.eza' },
    @{ Name = 'ripgrep'; Id = 'BurntSushi.ripgrep.MSVC' },
    @{ Name = 'fd'; Id = 'sharkdp.fd' },
    @{ Name = 'delta'; Id = 'dandavison.delta' }
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
        Where-Object { $_.name -like '*.exe' -and $_.name -like '*tacky*' } |
        Select-Object -First 1

    if (-not $asset) {
        throw 'Could not find a tacky-borders .exe asset in the latest GitHub release.'
    }

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $target -UseBasicParsing
    Add-UserPath -Path $installDir
    Write-Host "Installed: tacky-borders ($target)"
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
}

Install-VSCodeExtensions

Write-Host 'Software install script complete.'
