# Manual

This file is for practical operating notes that are more detailed than the
README. Keep the README focused on the supported happy path; use this manual for
manual checks, troubleshooting, and extra context.

## Fresh Machine Flow

Start with a preview:

```powershell
.\setup.ps1 -WhatIf
```

If the preview looks right, run:

```powershell
.\setup.ps1
```

After setup, restart open shells and desktop apps so new tools on `PATH` and
new configuration files are picked up.

## Useful Checks

Preview software installation:

```powershell
.\scripts\install-software.ps1 -WhatIf
```

Preview config application:

```powershell
.\scripts\apply-configs.ps1 -WhatIf
```

Preview config collection from the current machine:

```powershell
.\scripts\collect-configs.ps1 -WhatIf
```

Preview wallpaper changes:

```powershell
.\scripts\set-wallpaper.ps1 -WhatIf
```

Preview a theme switch:

```powershell
.\scripts\set-theme.ps1 -Name gruvbox -WhatIf
.\scripts\set-theme.ps1 -Name ristretto -WhatIf
```

Generate repo configs for a theme without changing the live machine:

```powershell
.\scripts\set-theme.ps1 -Name tokyo-night
```

Apply a generated theme to the current user:

```powershell
.\scripts\set-theme.ps1 -Name tokyo-night -Apply
```

Set Windows accent color while applying a theme:

```powershell
.\scripts\set-theme.ps1 -Name gruvbox -Apply -SetWindowsAccent
```

## VS Code Vim Keymaps

VS Code Vim is configured in two layers:

- `config\vscode\settings.json` contains VSCodeVim extension behavior and
  editor-local Vim mappings.
- `config\vscode\keybindings.json` contains VS Code keybindings with `when`
  clauses for app-wide and context-aware behavior.

This split keeps Vim editing behavior in the Vim extension while letting VS Code
handle sidebar, explorer, split, buffer, search, and navigation commands outside
normal editor text focus.

Useful defaults:

- `<space>` is the Vim leader.
- `<space><space>` opens quick file search.
- `<space>e` toggles/focuses Explorer, then returns to the editor when used
  from the sidebar.
- `<space>sg` searches across files.
- `<space>sh` and `<space>sv` split the editor.
- `<space>bd` closes the current editor; `<space>bo` closes other editors.
- `<space>ca`, `<space>cr`, and `<space>cd` trigger code action, rename, and
  problems.
- `gd`, `gr`, `gi`, `K`, `[d`, and `]d` provide common LSP/navigation actions.
- `jj` or `jk` exits insert mode.
- `Alt+j` and `Alt+k` move lines down/up.
- In Explorer focus, `a`, `r`, `d`, `c`, `x`, and `p` create, rename, delete,
  copy, cut, and paste files.

To edit keybindings in VS Code, use:

```text
Preferences: Open Keyboard Shortcuts (JSON)
```

That edits the live file at:

```text
%APPDATA%\Code\User\keybindings.json
```

After experimenting in VS Code, collect the live settings back into this repo:

```powershell
.\scripts\collect-configs.ps1
```

For focused changes, inspect the diff and keep only the VS Code files you meant
to change:

```powershell
git diff -- config\vscode\settings.json config\vscode\keybindings.json
```

## Desktop Startup

Register the desktop startup task:

```powershell
.\scripts\register-desktop-startup.ps1
```

Run the registered task without rebooting:

```powershell
Start-ScheduledTask -TaskPath '\Dotfiles\' -TaskName 'Dotfiles Desktop Startup'
```

Inspect the startup log:

```powershell
Get-Content .\var\logs\desktop-startup.log
```

Remove the task:

```powershell
.\scripts\unregister-desktop-startup.ps1
```

## Omarchy Reference Checkout

For parity work, keep a local Omarchy checkout next to this repo when possible:

```powershell
git clone https://github.com/basecamp/omarchy.git ..\omarchy
```

Compare behavior and feel against Omarchy first, then translate to Windows
using the local stack documented in `AGENTS.md` and `readme.md`.

The local reference checkout is intentionally not part of this repo. Keep it as
a sibling directory so comparisons are easy without mixing Linux source files
into the Windows setup.

## Notes To Expand

- Common post-install issues.
- Expected running processes after startup.
- How to update collected configs safely.
- How to compare a planned change against Omarchy.
- Manual app settings that cannot be reliably automated.
