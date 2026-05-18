[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Remove
)

$ErrorActionPreference = 'Stop'

$principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw 'CapsLock remapping writes to HKLM and must be run from an elevated PowerShell session.'
}

$keyboardLayoutPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$valueName = 'Scancode Map'

if ($Remove) {
    if ($PSCmdlet.ShouldProcess($keyboardLayoutPath, "Remove $valueName")) {
        Remove-ItemProperty -Path $keyboardLayoutPath -Name $valueName -ErrorAction SilentlyContinue
        Write-Host 'Removed CapsLock remap. Reboot or sign out/in for the change to take effect.'
    }

    return
}

# Maps CapsLock scan code 0x3A to F11 scan code 0x57.
[byte[]] $capsLockToF11 = @(
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00,
    0x57, 0x00, 0x3A, 0x00,
    0x00, 0x00, 0x00, 0x00
)

if ($PSCmdlet.ShouldProcess($keyboardLayoutPath, 'Map CapsLock to F11')) {
    New-Item -Path $keyboardLayoutPath -Force | Out-Null
    New-ItemProperty -Path $keyboardLayoutPath -Name $valueName -PropertyType Binary -Value $capsLockToF11 -Force | Out-Null
    Write-Host 'Mapped CapsLock to F11. Reboot or sign out/in for the change to take effect.'
}
