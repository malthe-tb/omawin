[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $Force,
    [switch] $SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backupRoot = Join-Path $repoRoot ('var\backups\apply-configs-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$documents = [Environment]::GetFolderPath('MyDocuments')

$items = @(
    @{
        Name = 'komorebi'
        Source = Join-Path $repoRoot 'config\komorebi'
        Destination = Join-Path $HOME '.config\komorebi'
    },
    @{
        Name = 'whkd'
        Source = Join-Path $repoRoot 'config\whkd\whkdrc'
        Destination = Join-Path $HOME '.config\whkdrc'
    },
    @{
        Name = 'yasb'
        Source = Join-Path $repoRoot 'config\yasb'
        Destination = Join-Path $HOME '.config\yasb'
    },
    @{
        Name = 'tacky-borders'
        Source = Join-Path $repoRoot 'config\tacky-borders'
        Destination = Join-Path $HOME '.config\tacky-borders'
    },
    @{
        Name = 'PowerShell 7 profile'
        Source = Join-Path $repoRoot 'config\powershell\Microsoft.PowerShell_profile.ps1'
        Destination = Join-Path $documents 'PowerShell\Microsoft.PowerShell_profile.ps1'
    },
    @{
        Name = 'Windows PowerShell profile'
        Source = Join-Path $repoRoot 'config\powershell\Microsoft.PowerShell_profile.ps1'
        Destination = Join-Path $documents 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
    },
    @{
        Name = 'Git config'
        Source = Join-Path $repoRoot 'config\git\.gitconfig'
        Destination = Join-Path $HOME '.gitconfig'
    },
    @{
        Name = 'VS Code settings'
        Source = Join-Path $repoRoot 'config\vscode\settings.json'
        Destination = Join-Path $env:APPDATA 'Code\User\settings.json'
    },
    @{
        Name = 'VS Code keybindings'
        Source = Join-Path $repoRoot 'config\vscode\keybindings.json'
        Destination = Join-Path $env:APPDATA 'Code\User\keybindings.json'
    },
    @{
        Name = 'VS Code MCP config'
        Source = Join-Path $repoRoot 'config\vscode\mcp.json'
        Destination = Join-Path $env:APPDATA 'Code\User\mcp.json'
    },
    @{
        Name = 'VS Code snippets'
        Source = Join-Path $repoRoot 'config\vscode\snippets'
        Destination = Join-Path $env:APPDATA 'Code\User\snippets'
    },
    @{
        Name = 'Starship'
        Source = Join-Path $repoRoot 'config\starship\starship.toml'
        Destination = Join-Path $HOME '.config\starship.toml'
    },
    @{
        Name = 'WezTerm'
        Source = Join-Path $repoRoot 'config\wezterm'
        Destination = Join-Path $HOME '.config\wezterm'
    }
)

function Test-Command {
    param([string] $Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-RelativePath {
    param(
        [string] $Root,
        [string] $Path
    )

    $rootWithSeparator = $Root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $Path.Substring($rootWithSeparator.Length)
}

function Backup-Path {
    param([string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $relative = $Path
    $drive = [System.IO.Path]::GetPathRoot($Path).TrimEnd('\').Replace(':', '')

    if ($drive) {
        $relative = Join-Path $drive $Path.Substring(([System.IO.Path]::GetPathRoot($Path)).Length)
    }

    $backupPath = Join-Path $backupRoot $relative

    if ($WhatIf) {
        Write-Host "Would back up: $Path -> $backupPath"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupPath) | Out-Null

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Copy-Item -LiteralPath $Path -Destination $backupPath -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    }

    Write-Host "Backed up: $Path -> $backupPath"
}

function Apply-File {
    param(
        [string] $Source,
        [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        return
    }

    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Backup-Path -Path $Destination
    }

    if ($WhatIf) {
        Write-Host "Would copy file: $Source -> $Destination"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Applied file: $Source -> $Destination"
}

function Apply-Directory {
    param(
        [string] $Source,
        [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        return
    }

    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Backup-Path -Path $Destination
    }

    $files = Get-ChildItem -LiteralPath $Source -File -Recurse

    foreach ($file in $files) {
        $relativePath = Get-RelativePath -Root $Source -Path $file.FullName
        $target = Join-Path $Destination $relativePath

        if ($WhatIf) {
            Write-Host "Would copy file: $($file.FullName) -> $target"
            continue
        }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Write-Host "Applied file: $($file.FullName) -> $target"
    }
}

foreach ($item in $items) {
    Write-Host "Applying $($item.Name)..."

    if (Test-Path -LiteralPath $item.Source -PathType Leaf) {
        Apply-File -Source $item.Source -Destination $item.Destination
        continue
    }

    if (Test-Path -LiteralPath $item.Source -PathType Container) {
        Apply-Directory -Source $item.Source -Destination $item.Destination
        continue
    }

    Write-Host "Skipped $($item.Name): source not found ($($item.Source))"
}

if (-not $SkipVSCodeExtensions) {
    Write-Host 'Applying VS Code extensions...'
    $extensionsPath = Join-Path $repoRoot 'config\vscode\extensions.txt'

    if (-not (Test-Path -LiteralPath $extensionsPath -PathType Leaf)) {
        Write-Host "Skipped VS Code extensions: source not found ($extensionsPath)"
    }
    elseif (-not (Test-Command 'code')) {
        Write-Host 'Skipped VS Code extensions: code command not found on PATH'
    }
    else {
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
}

if (-not $WhatIf -and (Test-Path -LiteralPath $backupRoot)) {
    Write-Host "Backups written to: $backupRoot"
}
