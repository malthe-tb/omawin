[CmdletBinding()]
param(
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$documents = [Environment]::GetFolderPath('MyDocuments')

$items = @(
    @{
        Name        = 'komorebi'
        Source      = Join-Path $HOME '.config\komorebi'
        Destination = Join-Path $repoRoot 'config\komorebi'
        Include     = @('*.json')
    },
    @{
        Name        = 'whkd'
        Source      = Join-Path $HOME '.config\whkdrc'
        Destination = Join-Path $repoRoot 'config\whkd\whkdrc'
    },
    @{
        Name        = 'yasb'
        Source      = Join-Path $HOME '.config\yasb'
        Destination = Join-Path $repoRoot 'config\yasb'
        Include     = @('*.yaml', '*.yml', '*.css')
    },
    @{
        Name        = 'tacky-borders'
        Source      = Join-Path $HOME '.config\tacky-borders'
        Destination = Join-Path $repoRoot 'config\tacky-borders'
        Include     = @('*.yaml', '*.yml', '*.json', '*.toml')
    },
    @{
        Name        = 'PowerShell 7 profile'
        Source      = Join-Path $documents 'PowerShell\Microsoft.PowerShell_profile.ps1'
        Destination = Join-Path $repoRoot 'config\powershell\Microsoft.PowerShell_profile.ps1'
    },
    @{
        Name        = 'Git config'
        Source      = Join-Path $HOME '.gitconfig'
        Destination = Join-Path $repoRoot 'config\git\.gitconfig'
    },
    @{
        Name        = 'VS Code settings'
        Source      = Join-Path $env:APPDATA 'Code\User\settings.json'
        Destination = Join-Path $repoRoot 'config\vscode\settings.json'
    },
    @{
        Name        = 'VS Code keybindings'
        Source      = Join-Path $env:APPDATA 'Code\User\keybindings.json'
        Destination = Join-Path $repoRoot 'config\vscode\keybindings.json'
    },
    @{
        Name        = 'VS Code MCP config'
        Source      = Join-Path $env:APPDATA 'Code\User\mcp.json'
        Destination = Join-Path $repoRoot 'config\vscode\mcp.json'
    },
    @{
        Name        = 'VS Code snippets'
        Source      = Join-Path $env:APPDATA 'Code\User\snippets'
        Destination = Join-Path $repoRoot 'config\vscode\snippets'
    },
    @{
        Name        = 'Starship'
        Source      = Join-Path $HOME '.config\starship.toml'
        Destination = Join-Path $repoRoot 'config\starship\starship.toml'
    },
    @{
        Name        = 'Windows Terminal'
        Source      = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
        Destination = Join-Path $repoRoot 'config\windows-terminal'
        Include     = @('settings.json')
    }
)

function Test-Command {
    param([string] $Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Copy-ConfigFile {
    param(
        [string] $Source,
        [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        return
    }

    if ($WhatIf) {
        Write-Host "Would copy file: $Source -> $Destination"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Copied file: $Source -> $Destination"
}

function Copy-ConfigDirectory {
    param(
        [string] $Source,
        [string] $Destination,
        [string[]] $Include = @('*'),
        [string[]] $Exclude = @('*.log')
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        return
    }

    $files = Get-ChildItem -LiteralPath $Source -File -Recurse | Where-Object {
        $fileName = $_.Name
        $included = $false
        $excluded = $false

        foreach ($pattern in $Include) {
            if ($fileName -like $pattern) {
                $included = $true
                break
            }
        }

        foreach ($pattern in $Exclude) {
            if ($fileName -like $pattern) {
                $excluded = $true
                break
            }
        }

        $included -and -not $excluded
    }

    foreach ($file in $files) {
        $sourceRoot = $Source.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
        $relativePath = $file.FullName.Substring($sourceRoot.Length)
        $target = Join-Path $Destination $relativePath

        if ($WhatIf) {
            Write-Host "Would copy file: $($file.FullName) -> $target"
            continue
        }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Write-Host "Copied file: $($file.FullName) -> $target"
    }
}

foreach ($item in $items) {
    Write-Host "Collecting $($item.Name)..."

    if (Test-Path -LiteralPath $item.Source -PathType Leaf) {
        Copy-ConfigFile -Source $item.Source -Destination $item.Destination
        continue
    }

    if (Test-Path -LiteralPath $item.Source -PathType Container) {
        Copy-ConfigDirectory -Source $item.Source -Destination $item.Destination -Include $item.Include
        continue
    }

    Write-Host "Skipped $($item.Name): source not found ($($item.Source))"
}

Write-Host 'Collecting VS Code extensions...'
if (Test-Command 'code') {
    $extensionsPath = Join-Path $repoRoot 'config\vscode\extensions.txt'

    if ($WhatIf) {
        Write-Host "Would export VS Code extensions -> $extensionsPath"
    }
    else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $extensionsPath) | Out-Null
        & code --list-extensions | Sort-Object | Set-Content -Path $extensionsPath -Encoding UTF8
        Write-Host "Exported VS Code extensions -> $extensionsPath"
    }
}
else {
    Write-Host 'Skipped VS Code extensions: code command not found on PATH'
}
