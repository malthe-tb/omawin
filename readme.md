# Windows 11 dotfiles

Personal Windows 11 setup inspired by [Omarchy](https://omarchy.org/), but focused on my own tools, configs, and workflow.

The goal is to be able to clone this repo on a fresh Windows machine, run a setup script, and quickly install/configure the software, shell tools, keyboard shortcuts, and dotfiles I use every day.

## Quick start

Preview the full setup without changing the machine:

```powershell
.\setup.ps1 -WhatIf
```

Run the full setup:

```powershell
.\setup.ps1
```

That runs software installation, applies configs, and registers the desktop startup task.

## Software

| Tool | Description |
| --- | --- |
| [Visual Studio Code](https://code.visualstudio.com/) | Main code editor with extension, settings, and keybinding sync/config support. |
| [Flow Launcher](https://www.flowlauncher.com/) | Keyboard-driven app launcher and command palette for Windows. |
| [Everything](https://www.voidtools.com/) | Very fast local file search/indexing tool for Windows. |
| [WezTerm](https://wezterm.com/) | GPU-accelerated terminal emulator with Lua-based configuration. |

## Window management

| Tool | Description |
| --- | --- |
| [komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager for Windows 10/11. |
| [whkd](https://github.com/LGUG2Z/whkd) | Simple hotkey daemon commonly used to bind keyboard shortcuts to komorebi commands. |
| [masir](https://github.com/LGUG2Z/masir) | Companion service in the komorebi ecosystem, started alongside komorebi when enabled. |
| [YASB](https://yasb.dev/) | Highly configurable Windows status bar with widgets, theming, and komorebi integration. |
| [tacky-borders](https://github.com/lukeyou05/tacky-borders) | Customizable active/inactive window borders for Windows 10/11. |

Start komorebi with the hotkey daemon and masir enabled:

```powershell
komorebic start --whkd --masir
```

### Startup

This repo includes scripts to start the window-management stack at Windows logon:

```powershell
.\scripts\register-desktop-startup.ps1
```

That creates a Scheduled Task named `\Dotfiles\Dotfiles Desktop Startup` for the current user. It runs:

```powershell
.\scripts\start-desktop.ps1
```

The startup script currently starts:

- `komorebic start --whkd --masir`
- `yasbc start --silent`
- `tacky-borders`

Test the startup task without rebooting:

```powershell
Start-ScheduledTask -TaskPath '\Dotfiles\' -TaskName 'Dotfiles Desktop Startup'
```

View the startup log:

```powershell
Get-Content .\var\logs\desktop-startup.log
```

Remove the startup task:

```powershell
.\scripts\unregister-desktop-startup.ps1
```

## Terminal

| Tool | Description |
| --- | --- |
| [Starship](https://starship.rs/) | Fast cross-shell prompt with a single config file. |
| [fzf](https://github.com/junegunn/fzf) | Interactive command-line fuzzy finder for files, history, processes, Git branches, and more. |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` command that learns frequently used directories. |
| [bat](https://github.com/sharkdp/bat) | `cat` replacement with syntax highlighting and Git integration. |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement with better defaults, colors, icons, and Git-aware output. |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast recursive text search, exposed as `rg`. |
| [fd](https://github.com/sharkdp/fd) | Simple, fast, user-friendly alternative to `find`. |
| [delta](https://github.com/dandavison/delta) | Syntax-highlighting pager for Git diffs, grep, blame, and related output. |
| [mise](https://mise.jdx.dev/) | Project-local dev tool version manager, environment loader, and task runner. |
| [CaskaydiaMono Nerd Font](https://www.nerdfonts.com/font-downloads) | Nerd Font patched Cascadia Mono variant for terminal icons and glyphs. |

Some of these should be wired up as aliases after install.

## Keyboard

Desired Caps Lock layer:

| Shortcut | Action |
| --- | --- |
| `Caps Lock` | `F11` / fullscreen |
| `Caps Lock + h` | Left arrow |
| `Caps Lock + j` | Down arrow |
| `Caps Lock + k` | Up arrow |
| `Caps Lock + l` | Right arrow |
| `Caps Lock + Enter` | Open terminal |
| `Caps Lock + Space` | Open launcher |

## Plan

- Store app and shell configurations in this repo.
- Add setup scripts for installing software and applying configs on a new Windows 11 machine.
- Prefer repeatable package-manager installs where possible.
- Keep manual steps documented when a setting cannot be automated cleanly.

## Config collection

Collect the current machine's known config files into this repo:

```powershell
.\scripts\collect-configs.ps1
```

Preview what would be collected without copying files:

```powershell
.\scripts\collect-configs.ps1 -WhatIf
```

Collected configs currently live under `config\` and include:

- `komorebi`
- `whkd`
- `yasb`
- `tacky-borders`
- PowerShell profile
- Git config
- VS Code settings/snippets
- Starship, when present
- WezTerm, when present

## Config apply

Apply the configs from this repo to the current machine:

```powershell
.\scripts\apply-configs.ps1
```

Preview what would be applied without copying files or installing extensions:

```powershell
.\scripts\apply-configs.ps1 -WhatIf
```

Skip VS Code extension installation:

```powershell
.\scripts\apply-configs.ps1 -SkipVSCodeExtensions
```

By default, existing destination files/folders are backed up under `var\backups\` before being overwritten.

## Software install

Install the software stack:

```powershell
.\scripts\install-software.ps1
```

Preview planned installs without changing the machine:

```powershell
.\scripts\install-software.ps1 -WhatIf
```

Useful install subsets:

```powershell
.\scripts\install-software.ps1 -SkipApps
.\scripts\install-software.ps1 -SkipWindowManagement
.\scripts\install-software.ps1 -SkipTerminal
.\scripts\install-software.ps1 -SkipFonts
.\scripts\install-software.ps1 -SkipVSCodeExtensions
```

The installer currently uses `winget` for the main apps/tools, downloads `tacky-borders` from the latest GitHub release because it does not currently have a winget package, and downloads `CaskaydiaMono Nerd Font` from the latest Nerd Fonts release.

Current winget packages:

| Tool | Package ID |
| --- | --- |
| Git | `Git.Git` |
| PowerShell 7 | `Microsoft.PowerShell` |
| Visual Studio Code | `Microsoft.VisualStudioCode` |
| Flow Launcher | `Flow-Launcher.Flow-Launcher` |
| Everything | `voidtools.Everything` |
| WezTerm | `wez.wezterm` |
| komorebi | `LGUG2Z.komorebi` |
| masir | `LGUG2Z.masir` |
| whkd | `LGUG2Z.whkd` |
| YASB | `AmN.yasb` |
| Starship | `Starship.Starship` |
| fzf | `junegunn.fzf` |
| zoxide | `ajeetdsouza.zoxide` |
| bat | `sharkdp.bat` |
| eza | `eza-community.eza` |
| ripgrep | `BurntSushi.ripgrep.MSVC` |
| fd | `sharkdp.fd` |
| delta | `dandavison.delta` |
| mise | `jdx.mise` |

Manual follow-up still needed:

- Restart shells/apps after installing tools that update `PATH`.
