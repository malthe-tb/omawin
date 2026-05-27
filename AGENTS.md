# Agent Instructions

This project is `omawin`: a Windows 11 dotfiles/setup repo inspired by Omarchy.
The goal is to deliver roughly 80% of the Omarchy experience on Windows, using
native Windows tools and conventions where a direct Linux/Hyprland equivalent
does not exist.

## Use Omarchy as the Product Reference

Before making product, UX, config, keybinding, install-flow, or documentation
changes, compare against the upstream Omarchy project.

Look for a local Omarchy checkout first by checking:

```powershell
echo $OMARCHY_PATH
```

If it is not set, look for `..\omarchy`. If that checkout is missing and
network access is available, clone it next to this repo:

```powershell
git clone https://github.com/basecamp/omarchy.git ..\omarchy
$env:OMARCHY_PATH = (Resolve-Path ..\omarchy).Path
```

If cloning is not possible, continue with the local project context and clearly
note that the Omarchy reference checkout was unavailable.

When using Omarchy as a reference, do not copy it blindly. Treat it as the design
and behavior source of truth, then translate intentionally to Windows.

## Project Direction

- Preserve the "beautiful, modern, opinionated desktop" feel.
- Prefer an integrated default setup over many optional branches.
- Keep setup flows simple enough to run from a fresh Windows 11 machine.
- Favor keyboard-driven workflows, tiling/window-management ergonomics, fast
  launch/search, strong terminal defaults, and tasteful visuals.
- Use Windows-native equivalents where they fit better than Linux-shaped ports.

## Current Windows Stack

The repo currently centers on:

- `komorebi`, `whkd`, `masir`, komorebi bar, and `tacky-borders` for the desktop shell.
- Windows Terminal, PowerShell, Starship, fzf, zoxide, bat, eza, ripgrep, fd,
  delta, and mise for terminal ergonomics.
- Flow Launcher and Everything for fast app/file access.
- VS Code settings, extensions, snippets, and MCP config.
- Wallpaper, cursor, startup task, and collected config application scripts.

Read `readme.md` before changing behavior, because it documents the current
public contract for installation, config collection, config application, startup,
software installation, and wallpaper handling.

Read `docs\ROADMAP.md` for active project direction, planned Omarchy parity
work, open questions, and rough priorities. Read `docs\MANUAL.md` for
operator-facing notes that are more detailed or experimental than the README.
Read `docs\ARCHITECTURE.md` before changing internal structure or adding a new
tool surface.

## Implementation Guidelines

- Keep scripts idempotent where practical.
- Support `-WhatIf` for scripts that change the machine.
- Back up user config before overwriting it, matching the existing
  `var\backups\` convention.
- Prefer PowerShell-native APIs and cmdlets for Windows automation.
- Avoid hard-coding user-specific absolute paths unless there is no reasonable
  alternative.
- Keep config files collected under `config\` and assets under `assets\`.
- Keep generated logs and backups under `var\`.
- Do not introduce unrelated refactors while making a focused change.

## Omarchy Translation Rules

When porting or adapting an Omarchy feature:

- Identify the user-facing behavior in Omarchy first.
- Map the closest Windows tool, config file, script, or workflow.
- Preserve the feel and keyboard ergonomics when exact parity is impossible.
- Document differences that a user would notice.
- Prefer a working Windows-native approximation over a fragile exact clone.

Examples:

- Hyprland behavior should usually map to `komorebi` and `whkd`.
- Waybar/status behavior should usually map to komorebi bar.
- Shell/terminal polish should map to PowerShell, Windows Terminal, Starship,
  and the installed CLI tools.
- Omarchy menu/launcher behavior should usually map to Flow Launcher, whkd
  bindings, or small PowerShell helper scripts.

## Testing and Verification

For script changes, run the safest relevant checks first:

```powershell
.\setup.ps1 -WhatIf
.\scripts\install-software.ps1 -WhatIf
.\scripts\apply-configs.ps1 -WhatIf
.\scripts\collect-configs.ps1 -WhatIf
.\scripts\set-wallpaper.ps1 -WhatIf
```

For targeted changes, run the specific script with `-WhatIf` and inspect the
paths or commands it reports. Only run machine-changing commands when the user
asked for that outcome or explicitly approved it.

## Documentation

Keep `readme.md` aligned with the actual scripts and supported options. If a
script gains or loses a public flag, update the README in the same change.

Use `docs\ROADMAP.md` for future plans, unfinished ideas, comparisons against
Omarchy, and prioritization notes. Use `docs\MANUAL.md` for practical setup,
maintenance, troubleshooting, and manual follow-up steps that are too detailed
for the README. Use `docs\ARCHITECTURE.md` for repo structure, component
boundaries, and design decisions about the future `omawin` tools.

Use concise, practical documentation. This repo should feel like a setup you can
actually run, not a catalog of possibilities.
