[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Name,
    [switch] $Apply,
    [switch] $WhatIf,
    [switch] $SkipWallpaper,
    [switch] $SetWindowsAccent,
    [switch] $SkipVSCodeExtensions
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$themePath = Join-Path $repoRoot "themes\$Name\theme.json"

if (-not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
    $availableThemes = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'themes') -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'theme.json') -PathType Leaf } |
        Select-Object -ExpandProperty Name

    throw "Theme not found: $Name. Available themes: $($availableThemes -join ', ')"
}

$theme = Get-Content -LiteralPath $themePath -Raw | ConvertFrom-Json
$colors = $theme.colors
$terminal = $theme.terminal

function Write-ThemeFile {
    param(
        [string] $Path,
        [string] $Content
    )

    if ($WhatIf) {
        Write-Host "Would write: $Path"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "Wrote: $Path"
}

function ConvertTo-PrettyJson {
    param([object] $InputObject)

    $InputObject | ConvertTo-Json -Depth 100
}

function Set-JsonProperty {
    param(
        [object] $Object,
        [string] $Name,
        [object] $Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    }
    else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Convert-HexToRgb {
    param([string] $Hex)

    $value = $Hex.TrimStart('#')

    return [pscustomobject]@{
        R = [Convert]::ToByte($value.Substring(0, 2), 16)
        G = [Convert]::ToByte($value.Substring(2, 2), 16)
        B = [Convert]::ToByte($value.Substring(4, 2), 16)
    }
}

function Convert-HexToArgbDword {
    param([string] $Hex)

    $rgb = Convert-HexToRgb -Hex $Hex
    return [Convert]::ToUInt32(('ff{0:x2}{1:x2}{2:x2}' -f $rgb.R, $rgb.G, $rgb.B), 16)
}

function Convert-HexToAbgrDword {
    param([string] $Hex)

    $rgb = Convert-HexToRgb -Hex $Hex
    return [Convert]::ToUInt32(('ff{0:x2}{1:x2}{2:x2}' -f $rgb.B, $rgb.G, $rgb.R), 16)
}

function Update-KomorebiConfig {
    $path = Join-Path $repoRoot 'config\komorebi\komorebi.json'
    $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json

    if (-not $json.theme) {
        Set-JsonProperty -Object $json -Name 'theme' -Value ([pscustomobject]@{})
    }

    Set-JsonProperty -Object $json.theme -Name 'palette' -Value $theme.komorebiTheme.palette
    Set-JsonProperty -Object $json.theme -Name 'name' -Value $theme.komorebiTheme.name
    Set-JsonProperty -Object $json.theme -Name 'unfocused_border' -Value $theme.komorebiTheme.unfocusedBorder
    Set-JsonProperty -Object $json.theme -Name 'bar_accent' -Value $theme.komorebiTheme.accent

    Write-ThemeFile -Path $path -Content (ConvertTo-PrettyJson $json)
}

function Update-KomorebiBarConfig {
    $path = Join-Path $repoRoot 'config\komorebi\komorebi.bar.json'
    $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json

    Set-JsonProperty -Object $json -Name 'font_family' -Value $theme.fontMono

    if (-not $json.theme) {
        Set-JsonProperty -Object $json -Name 'theme' -Value ([pscustomobject]@{})
    }

    Set-JsonProperty -Object $json.theme -Name 'palette' -Value $theme.komorebiTheme.palette
    Set-JsonProperty -Object $json.theme -Name 'name' -Value $theme.komorebiTheme.name
    Set-JsonProperty -Object $json.theme -Name 'accent' -Value $theme.komorebiTheme.accent

    Write-ThemeFile -Path $path -Content (ConvertTo-PrettyJson $json)
}

function Update-WindowsTerminalConfig {
    $path = Join-Path $repoRoot 'config\windows-terminal\settings.json'
    $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $schemeName = "Omawin $($theme.displayName)"

    $scheme = [pscustomobject]@{
        name = $schemeName
        background = $colors.background
        foreground = $colors.foreground
        selectionBackground = $colors.surfaceAlt
        cursorColor = $colors.accent
        black = $terminal.black
        red = $terminal.red
        green = $terminal.green
        yellow = $terminal.yellow
        blue = $terminal.blue
        purple = $terminal.purple
        cyan = $terminal.cyan
        white = $terminal.white
        brightBlack = $terminal.brightBlack
        brightRed = $terminal.brightRed
        brightGreen = $terminal.brightGreen
        brightYellow = $terminal.brightYellow
        brightBlue = $terminal.brightBlue
        brightPurple = $terminal.brightPurple
        brightCyan = $terminal.brightCyan
        brightWhite = $terminal.brightWhite
    }

    $json.schemes = @($json.schemes | Where-Object { $_.name -notlike 'Omawin *' })
    $json.schemes += $scheme

    Set-JsonProperty -Object $json.profiles.defaults -Name 'colorScheme' -Value $schemeName

    if (-not $json.profiles.defaults.font) {
        Set-JsonProperty -Object $json.profiles.defaults -Name 'font' -Value ([pscustomobject]@{})
    }

    Set-JsonProperty -Object $json.profiles.defaults.font -Name 'face' -Value $theme.fontMono

    Write-ThemeFile -Path $path -Content (ConvertTo-PrettyJson $json)
}

function Update-TackyBordersConfig {
    $path = Join-Path $repoRoot 'config\tacky-borders\config.yaml'
    $content = Get-Content -LiteralPath $path -Raw

    $content = [regex]::Replace(
        $content,
        '(?ms)^  active_color:\r?\n    colors: \["#[0-9a-fA-F]{6}", "#[0-9a-fA-F]{6}"\]',
        "  active_color:`n    colors: [`"$($colors.accent)`", `"$($colors.accentAlt)`"]"
    )

    $content = [regex]::Replace(
        $content,
        '(?ms)^  inactive_color:\r?\n    colors: \["#[0-9a-fA-F]{6}", "#[0-9a-fA-F]{6}"\]',
        "  inactive_color:`n    colors: [`"$($colors.border)`", `"$($colors.surfaceAlt)`"]"
    )

    $content = [regex]::Replace($content, 'stack_color: "#[0-9a-fA-F]{6}"', "stack_color: `"$($colors.accentAlt)`"")
    $content = [regex]::Replace($content, 'monocle_color: "#[0-9a-fA-F]{6}"', "monocle_color: `"$($colors.magenta)`"")
    $content = [regex]::Replace($content, 'floating_color: "#[0-9a-fA-F]{6}"', "floating_color: `"$($colors.cyan)`"")

    Write-ThemeFile -Path $path -Content $content.TrimEnd()
}

function Set-WindowsAccent {
    $accent = $colors.accent
    $dwmPath = 'HKCU:\Software\Microsoft\Windows\DWM'
    $personalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    if ($WhatIf) {
        Write-Host "Would set Windows accent color: $accent"
        return
    }

    New-Item -Path $dwmPath -Force | Out-Null
    New-Item -Path $personalizePath -Force | Out-Null

    New-ItemProperty -Path $dwmPath -Name AccentColor -Value (Convert-HexToAbgrDword -Hex $accent) -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $dwmPath -Name ColorizationColor -Value (Convert-HexToArgbDword -Hex $accent) -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $dwmPath -Name ColorPrevalence -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $personalizePath -Name AppsUseLightTheme -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $personalizePath -Name SystemUsesLightTheme -Value 0 -PropertyType DWord -Force | Out-Null

    Write-Host "Set Windows accent color: $accent"
}

function Update-VSCodeConfig {
    $path = Join-Path $repoRoot 'config\vscode\settings.json'
    $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json

    Set-JsonProperty -Object $json -Name 'workbench.colorTheme' -Value $theme.vscodeTheme
    Set-JsonProperty -Object $json -Name 'editor.fontFamily' -Value "'$($theme.fontMono)', Consolas, monospace"
    Set-JsonProperty -Object $json -Name 'terminal.integrated.fontFamily' -Value $theme.fontMono
    Set-JsonProperty -Object $json -Name 'workbench.colorCustomizations' -Value ([pscustomobject]@{
        'activityBar.background' = $colors.background
        'activityBar.foreground' = $colors.foreground
        'sideBar.background' = $colors.background
        'sideBar.foreground' = $colors.foreground
        'editorGroupHeader.tabsBackground' = $colors.background
        'panel.background' = $colors.background
        'terminal.background' = $colors.background
        'statusBar.background' = $colors.surface
        'statusBar.foreground' = $colors.foreground
        'titleBar.activeBackground' = $colors.background
        'titleBar.activeForeground' = $colors.foreground
    })

    Write-ThemeFile -Path $path -Content (ConvertTo-PrettyJson $json)

    $extensionsPath = Join-Path $repoRoot 'config\vscode\extensions.txt'
    $extensions = @()

    if (Test-Path -LiteralPath $extensionsPath -PathType Leaf) {
        $extensions = Get-Content -LiteralPath $extensionsPath
    }

    if ($theme.vscodeExtension -and ($extensions -notcontains $theme.vscodeExtension)) {
        $extensions += $theme.vscodeExtension
        Write-ThemeFile -Path $extensionsPath -Content (($extensions | Where-Object { $_ }) -join [Environment]::NewLine)
    }
}

function Update-NeovimConfig {
    $path = Join-Path $repoRoot 'config\nvim\lua\config\omawin-theme.lua'
    $monokaiProFilter = if ($theme.neovimMonokaiProFilter) { "`"$($theme.neovimMonokaiProFilter)`"" } else { 'nil' }
    $content = @"
return {
  name = "$($theme.name)",
  colorscheme = "$($theme.neovimColorscheme)",
  monokai_pro_filter = $monokaiProFilter,
}
"@

    Write-ThemeFile -Path $path -Content $content.TrimEnd()
}

function Update-CurrentThemeConfig {
    $path = Join-Path $repoRoot 'config\omawin\theme.json'
    $content = @{
        currentTheme = $theme.name
    } | ConvertTo-Json

    Write-ThemeFile -Path $path -Content $content
}

Update-CurrentThemeConfig
Update-KomorebiConfig
Update-KomorebiBarConfig
Update-WindowsTerminalConfig
Update-TackyBordersConfig
Update-VSCodeConfig
Update-NeovimConfig

if ($Apply) {
    if ($WhatIf) {
        Write-Host 'Would apply generated configs.'
        if (-not $SkipWallpaper) {
            $wallpaperPath = Join-Path $repoRoot ($theme.wallpaper -replace '/', '\')
            Write-Host "Would set themed wallpaper: $wallpaperPath"
        }
        if ($SetWindowsAccent) {
            Set-WindowsAccent
        }
    }
    else {
        & (Join-Path $repoRoot 'scripts\apply-configs.ps1') -SkipVSCodeExtensions:$SkipVSCodeExtensions

        if ($SetWindowsAccent) {
            Set-WindowsAccent
        }

        if (-not $SkipWallpaper) {
            $wallpaperPath = Join-Path $repoRoot ($theme.wallpaper -replace '/', '\')

            if (Test-Path -LiteralPath $wallpaperPath -PathType Leaf) {
                & (Join-Path $repoRoot 'scripts\set-wallpaper.ps1') -WallpaperPath $wallpaperPath
            }
            else {
                Write-Warning "Skipped wallpaper: source not found ($wallpaperPath)"
            }
        }
    }
}

Write-Host "Theme selected: $($theme.displayName)"
