[CmdletBinding()]
param(
    [switch] $WhatIf,
    [ValidateSet('Classic', 'Ice', 'Amber')]
    [string] $Color = 'Classic',
    [ValidateSet('Regular', 'Large', 'ExtraLarge')]
    [string] $Size = 'Regular',
    [switch] $Right,
    [string] $Version = 'latest'
)

$ErrorActionPreference = 'Stop'

$repo = 'ful1e5/Bibata_Cursor'
$themeName = "Bibata-Modern-$Color"
$assetPrefix = if ($Right) { "$themeName-Right-Windows" } else { "$themeName-Windows" }
$cursorRoot = Join-Path $env:LOCALAPPDATA 'Cursors'
$cursorRegistryPath = 'HKCU:\Control Panel\Cursors'
$schemeRegistryPath = 'HKCU:\Control Panel\Cursors\Schemes'
$cursorRoles = @(
    'Arrow',
    'Help',
    'AppStarting',
    'Wait',
    'Crosshair',
    'IBeam',
    'NWPen',
    'No',
    'SizeNS',
    'SizeWE',
    'SizeNWSE',
    'SizeNESW',
    'SizeAll',
    'UpArrow',
    'Hand',
    'Pin',
    'Person'
)

function Remove-Quotes {
    param([string] $Value)

    if ($null -eq $Value) {
        return $null
    }

    return $Value.Trim().Trim('"')
}

function Split-InfCsv {
    param([string] $Value)

    $items = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inQuotes = $false

    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '"') {
            $inQuotes = -not $inQuotes
            [void] $current.Append($character)
            continue
        }

        if ($character -eq ',' -and -not $inQuotes) {
            $items.Add((Remove-Quotes $current.ToString()))
            [void] $current.Clear()
            continue
        }

        [void] $current.Append($character)
    }

    $items.Add((Remove-Quotes $current.ToString()))
    return $items.ToArray()
}

function Read-InfFile {
    param([string] $Path)

    $sections = @{}
    $sectionName = $null

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()

        if (-not $line -or $line.StartsWith(';')) {
            continue
        }

        if ($line -match '^\[(.+)\]$') {
            $sectionName = $Matches[1]
            if (-not $sections.ContainsKey($sectionName)) {
                $sections[$sectionName] = New-Object System.Collections.Generic.List[string]
            }
            continue
        }

        if ($sectionName) {
            $sections[$sectionName].Add($line)
        }
    }

    return $sections
}

function Get-InfStrings {
    param([hashtable] $Sections)

    $strings = @{}

    if (-not $Sections.ContainsKey('Strings')) {
        return $strings
    }

    foreach ($line in $Sections['Strings']) {
        $parts = $line -split '=', 2
        if ($parts.Count -ne 2) {
            continue
        }

        $strings[$parts[0].Trim()] = Remove-Quotes $parts[1]
    }

    return $strings
}

function Expand-InfValue {
    param(
        [string] $Value,
        [hashtable] $Strings,
        [string] $InstallDir
    )

    if (-not $Value) {
        return $Value
    }

    $expanded = Remove-Quotes $Value

    foreach ($key in $Strings.Keys) {
        $expanded = $expanded.Replace("%$key%", $Strings[$key])
    }

    $fileName = Split-Path -Path $expanded -Leaf

    if ($fileName -and ([IO.Path]::GetExtension($fileName) -in '.cur', '.ani')) {
        return Join-Path $InstallDir $fileName
    }

    $expanded = $expanded.Replace('%10%\', "$InstallDir\").Replace('%10%', $InstallDir)

    if (-not [IO.Path]::IsPathRooted($expanded)) {
        $expanded = Join-Path $InstallDir $expanded
    }

    return $expanded
}

function Test-CursorFile {
    param([string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $item = Get-Item -LiteralPath $Path
    return ($item.Length -gt 0)
}

function Get-CursorAssignments {
    param(
        [hashtable] $Sections,
        [hashtable] $Strings,
        [string] $InstallDir
    )

    $assignments = @{}

    if (-not $Sections.ContainsKey('Wreg')) {
        throw 'The cursor installer INF does not contain a [Wreg] section.'
    }

    foreach ($line in $Sections['Wreg']) {
        $columns = Split-InfCsv $line

        if ($columns.Count -lt 5) {
            continue
        }

        $role = Remove-Quotes $columns[2]

        if ($cursorRoles -notcontains $role) {
            continue
        }

        $assignments[$role] = Expand-InfValue -Value (Remove-Quotes $columns[4]) -Strings $Strings -InstallDir $InstallDir
    }

    foreach ($role in $cursorRoles) {
        if (-not $assignments.ContainsKey($role)) {
            throw "The cursor installer INF did not define the $role cursor."
        }

        if (-not (Test-CursorFile -Path $assignments[$role])) {
            throw "The $role cursor points to a missing or empty file: $($assignments[$role])"
        }
    }

    return $assignments
}

function Get-SchemeName {
    param(
        [hashtable] $Sections,
        [hashtable] $Strings
    )

    if ($Strings.ContainsKey('SCHEME_NAME')) {
        return $Strings['SCHEME_NAME']
    }

    if ($Sections.ContainsKey('Scheme.Reg')) {
        foreach ($line in $Sections['Scheme.Reg']) {
            $columns = Split-InfCsv $line
            if ($columns.Count -ge 3) {
                $name = Remove-Quotes $columns[2]
                foreach ($key in $Strings.Keys) {
                    $name = $name.Replace("%$key%", $Strings[$key])
                }
                return $name
            }
        }
    }

    return $themeName
}

function Send-CursorReload {
    if (-not ('CursorChangeNotifier' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class CursorChangeNotifier
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
'@
    }

    [CursorChangeNotifier]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x0001 -bor 0x0002) | Out-Null
}

function Select-InstallInf {
    param(
        [string] $ExtractPath,
        [string] $PreferredSize
    )

    $installers = Get-ChildItem -LiteralPath $ExtractPath -Recurse -File -Filter 'install.inf'

    if (-not $installers) {
        throw 'Could not find install.inf inside the Bibata Windows cursor archive.'
    }

    $sizePattern = switch ($PreferredSize) {
        'ExtraLarge' { 'extra\s*large|xlarge|xl' }
        'Large' { 'large' }
        default { 'regular|normal|default' }
    }

    $match = $installers |
        Where-Object { $_.DirectoryName -match $sizePattern } |
        Sort-Object FullName |
        Select-Object -First 1

    if ($match) {
        return $match
    }

    return $installers | Sort-Object FullName | Select-Object -First 1
}

function Get-BibataAsset {
    if ($Version -eq 'latest') {
        $releaseUri = "https://api.github.com/repos/$repo/releases/latest"
    } else {
        $releaseUri = "https://api.github.com/repos/$repo/releases/tags/$Version"
    }

    $release = Invoke-RestMethod -Uri $releaseUri -Headers @{ 'User-Agent' = 'dotfiles-bootstrap' }
    $asset = $release.assets |
        Where-Object { $_.name -eq "$assetPrefix.zip" } |
        Select-Object -First 1

    if (-not $asset) {
        $available = ($release.assets | Where-Object { $_.name -like '*Windows.zip' } | Select-Object -ExpandProperty name) -join ', '
        throw "Could not find $assetPrefix.zip in $($release.tag_name). Available Windows assets: $available"
    }

    return $asset
}

$displayName = if ($Version -eq 'latest') { "$assetPrefix from the latest release" } else { "$assetPrefix from $Version" }

if ($WhatIf) {
    Write-Host "Would download and install: $displayName"
    Write-Host "Would install cursor files under: $cursorRoot"
    Write-Host "Would activate the cursor scheme for the current user under: $cursorRegistryPath"
    return
}

Write-Host "Installing: $displayName"

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
$zipPath = Join-Path $tempRoot "$assetPrefix.zip"
$extractPath = Join-Path $tempRoot 'extract'

try {
    New-Item -ItemType Directory -Force -Path $tempRoot, $extractPath, $cursorRoot | Out-Null

    $asset = Get-BibataAsset
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $installInf = Select-InstallInf -ExtractPath $extractPath -PreferredSize $Size
    $sections = Read-InfFile -Path $installInf.FullName
    $strings = Get-InfStrings -Sections $sections
    $schemeName = Get-SchemeName -Sections $sections -Strings $strings
    $installDir = Join-Path $cursorRoot $schemeName

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null

    $cursorFiles = Get-ChildItem -LiteralPath $installInf.DirectoryName -Recurse -File |
        Where-Object { $_.Extension -in '.cur', '.ani' }

    if (-not $cursorFiles) {
        throw "Could not find .cur or .ani files near $($installInf.FullName)"
    }

    foreach ($cursorFile in $cursorFiles) {
        Copy-Item -LiteralPath $cursorFile.FullName -Destination (Join-Path $installDir $cursorFile.Name) -Force
    }

    $assignments = Get-CursorAssignments -Sections $sections -Strings $strings -InstallDir $installDir
    New-Item -Path $cursorRegistryPath -Force | Out-Null
    New-Item -Path $schemeRegistryPath -Force | Out-Null

    foreach ($role in $cursorRoles) {
        New-ItemProperty -Path $cursorRegistryPath -Name $role -Value $assignments[$role] -PropertyType String -Force | Out-Null
    }

    $schemeValue = ($cursorRoles | ForEach-Object { $assignments[$_] }) -join ','
    New-ItemProperty -Path $schemeRegistryPath -Name $schemeName -Value $schemeValue -PropertyType String -Force | Out-Null
    Set-Item -Path $cursorRegistryPath -Value $schemeName
    New-ItemProperty -Path $cursorRegistryPath -Name 'Scheme Source' -Value 1 -PropertyType DWord -Force | Out-Null

    Send-CursorReload
    Write-Host "Installed and activated: $schemeName"
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
