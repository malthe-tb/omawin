[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Group = 'commands',

    [Parameter(Position = 1)]
    [string] $Command,

    [Parameter(ValueFromRemainingArguments)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$repoRootFile = Join-Path $repoRoot 'repo-root.txt'

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'setup.ps1') -PathType Leaf)) {
    if ($env:OMAWIN_REPO -and (Test-Path -LiteralPath (Join-Path $env:OMAWIN_REPO 'setup.ps1') -PathType Leaf)) {
        $repoRoot = $env:OMAWIN_REPO
    }
    elseif (Test-Path -LiteralPath $repoRootFile -PathType Leaf) {
        $repoRoot = (Get-Content -LiteralPath $repoRootFile -Raw).Trim()
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'setup.ps1') -PathType Leaf)) {
    throw "Could not find the omawin repo root. Set OMAWIN_REPO or run this command from the repo bin directory."
}

$scriptsRoot = Join-Path $repoRoot 'scripts'

function Invoke-RepoScript {
    param(
        [string] $Name,
        [string[]] $Arguments = @()
    )

    $script = Join-Path $scriptsRoot $Name
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Script not found: $script"
    }

    & $script @Arguments
}

function Show-Commands {
    @'
omawin commands
omawin menu
omawin setup preview
omawin setup run
omawin config apply
omawin config collect
omawin desktop start
omawin desktop restart
omawin desktop status
omawin desktop register
omawin desktop unregister
omawin desktop logs
omawin wallpaper set
omawin theme list
omawin theme set <name> [-Apply] [-SetWindowsAccent]
'@
}

function Get-ThemeNames {
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'themes') -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'theme.json') -PathType Leaf } |
        Select-Object -ExpandProperty Name
}

function Start-OmawinCommand {
    param([string[]] $Arguments)

    $quoted = @(
        '-NoExit'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        "`"$PSCommandPath`""
    ) + ($Arguments | ForEach-Object {
        if ($_ -match '\s') { "`"$_`"" } else { $_ }
    })

    Start-Process -FilePath powershell.exe -ArgumentList ($quoted -join ' ')
}

function Show-Menu {
    $items = @(
        [pscustomobject]@{ Label = 'Desktop: start stack'; Args = @('desktop', 'start') },
        [pscustomobject]@{ Label = 'Desktop: restart stack'; Args = @('desktop', 'restart') },
        [pscustomobject]@{ Label = 'Desktop: status'; Args = @('desktop', 'status') },
        [pscustomobject]@{ Label = 'Desktop: open startup log'; Args = @('desktop', 'logs') },
        [pscustomobject]@{ Label = 'Config: apply repo configs'; Args = @('config', 'apply') },
        [pscustomobject]@{ Label = 'Config: collect live configs'; Args = @('config', 'collect') },
        [pscustomobject]@{ Label = 'Setup: preview full setup'; Args = @('setup', 'preview') },
        [pscustomobject]@{ Label = 'Wallpaper: set default'; Args = @('wallpaper', 'set') }
    )

    foreach ($theme in Get-ThemeNames) {
        $items += [pscustomobject]@{
            Label = "Theme: apply $theme"
            Args = @('theme', 'set', $theme, '-Apply')
        }
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $form = [Windows.Forms.Form]::new()
        $form.Text = 'omawin'
        $form.StartPosition = 'CenterScreen'
        $form.Width = 420
        $form.Height = 520
        $form.TopMost = $true
        $form.KeyPreview = $true
        $form.Font = [Drawing.Font]::new('Segoe UI', 10)

        $list = [Windows.Forms.ListBox]::new()
        $list.Dock = 'Fill'
        $list.IntegralHeight = $false
        $list.DisplayMember = 'Label'
        $list.DataSource = $items

        $form.Controls.Add($list)
        $form.AcceptButton = $null

        $list.Add_DoubleClick({
            $form.Tag = $list.SelectedItem
            $form.Close()
        })
        $form.Add_KeyDown({
            if ($_.KeyCode -eq 'Enter') {
                $form.Tag = $list.SelectedItem
                $form.Close()
            }
            elseif ($_.KeyCode -eq 'Escape') {
                $form.Close()
            }
        })

        [void] $form.ShowDialog()

        if ($form.Tag) {
            Start-OmawinCommand -Arguments $form.Tag.Args
        }
    }
    catch {
        Write-Warning "GUI menu unavailable: $($_.Exception.Message)"
        Show-Commands
    }
}

switch ($Group.ToLowerInvariant()) {
    'commands' { Show-Commands }
    'menu' { Show-Menu }
    'setup' {
        switch ($Command) {
            'preview' { & (Join-Path $repoRoot 'setup.ps1') -WhatIf }
            'run' { & (Join-Path $repoRoot 'setup.ps1') }
            default { throw 'Usage: omawin setup <preview|run>' }
        }
    }
    'config' {
        switch ($Command) {
            'apply' { Invoke-RepoScript -Name 'apply-configs.ps1' -Arguments $Rest }
            'collect' { Invoke-RepoScript -Name 'collect-configs.ps1' -Arguments $Rest }
            default { throw 'Usage: omawin config <apply|collect>' }
        }
    }
    'desktop' {
        switch ($Command) {
            'start' { Invoke-RepoScript -Name 'start-desktop.ps1' -Arguments $Rest }
            'restart' { Invoke-RepoScript -Name 'start-desktop.ps1' -Arguments (@('-Restart') + $Rest) }
            'register' { Invoke-RepoScript -Name 'register-desktop-startup.ps1' -Arguments (@('-Force') + $Rest) }
            'unregister' { Invoke-RepoScript -Name 'unregister-desktop-startup.ps1' -Arguments $Rest }
            'logs' { Get-Content -LiteralPath (Join-Path $repoRoot 'var\logs\desktop-startup.log') -Tail 120 }
            'status' {
                Get-Process -Name komorebi, whkd, masir, komorebi-bar, tacky-borders -ErrorAction SilentlyContinue |
                    Select-Object ProcessName, Id, Path
            }
            default { throw 'Usage: omawin desktop <start|restart|status|register|unregister|logs>' }
        }
    }
    'wallpaper' {
        switch ($Command) {
            'set' { Invoke-RepoScript -Name 'set-wallpaper.ps1' -Arguments $Rest }
            default { throw 'Usage: omawin wallpaper set' }
        }
    }
    'theme' {
        switch ($Command) {
            'list' { Get-ThemeNames }
            'set' {
                if (-not $Rest -or -not $Rest[0]) {
                    throw 'Usage: omawin theme set <name> [-Apply] [-SetWindowsAccent]'
                }

                $themeArgs = @('-Name', $Rest[0])
                if ($Rest.Count -gt 1) {
                    $themeArgs += $Rest[1..($Rest.Count - 1)]
                }

                Invoke-RepoScript -Name 'set-theme.ps1' -Arguments $themeArgs
            }
            default { throw 'Usage: omawin theme <list|set>' }
        }
    }
    default {
        throw "Unknown omawin command group: $Group"
    }
}
