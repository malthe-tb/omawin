# Windows 11 dotfiles

Windows 11 setup inspired by [Omarchy](https://omarchy.org/).

Omarchy is a beautiful, modern, opinionated desktop.

The goal is to deliver a similar experience on Windows 11: beautiful, modern,
opinionated, and predominantly keyboard-driven.

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
It also applies the wallpaper from `assets\wallpapers\dr15.jpg`.

## Software

| Tool | Description |
| --- | --- |
| [Visual Studio Code](https://code.visualstudio.com/) | Main code editor with extension, settings, and keybinding sync/config support. |
| [Zen Browser](https://zen-browser.app/) | Default installed browser, matching the existing Zen-focused web app and browser hotkeys. |
| [Flow Launcher](https://www.flowlauncher.com/) | Keyboard-driven app launcher and command palette for Windows. |
| [Everything](https://www.voidtools.com/) | Very fast local file search/indexing tool for Windows. |
| [Windows Terminal](https://github.com/microsoft/terminal) | Primary terminal emulator, launched with `Win + Enter`. |

## Window management

| Tool | Description |
| --- | --- |
| [komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager for Windows 10/11. |
| [whkd](https://github.com/LGUG2Z/whkd) | Simple hotkey daemon commonly used to bind keyboard shortcuts to komorebi commands. |
| [masir](https://github.com/LGUG2Z/masir) | Companion service in the komorebi ecosystem, started alongside komorebi when enabled. |
| [tacky-borders](https://github.com/lukeyou05/tacky-borders) | Customizable active/inactive window borders for Windows 10/11. |

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
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for Git, used directly and by LazyVim integrations. |
| [Neovim](https://neovim.io/) | Terminal-native editor with a LazyVim-based repo config under `config\nvim`. |
| [CaskaydiaMono Nerd Font](https://www.nerdfonts.com/font-downloads) | Nerd Font patched Cascadia Mono variant for terminal icons and glyphs. |
| [Bibata Modern Classic](https://github.com/ful1e5/Bibata_Cursor) | Modern Windows cursor theme installed and activated for the current user. |

The PowerShell profile wires common shortcuts such as `n` for Neovim, `ls` via
eza, `cat` via bat, and PowerShell-native wrappers for `cp`, `mv`, `rm`,
`mkdir`, and `touch`.

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

- `komorebic start --whkd --masir --bar`
- `tacky-borders`


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
- `tacky-borders`
- PowerShell profile
- Git config
- VS Code settings/keybindings/snippets
- Starship, when present
- Neovim, when present
- Windows Terminal settings, when present

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

## Themes

Generate repo configs for a supported theme:

```powershell
.\scripts\set-theme.ps1 -Name tokyo-night
.\scripts\set-theme.ps1 -Name gruvbox
.\scripts\set-theme.ps1 -Name ristretto
```

Preview a theme switch without changing files:

```powershell
.\scripts\set-theme.ps1 -Name gruvbox -WhatIf
```

Generate the configs, apply them to the current user, and set the themed wallpaper:

```powershell
.\scripts\set-theme.ps1 -Name tokyo-night -Apply
```

Also set the current user's Windows accent color from the theme:

```powershell
.\scripts\set-theme.ps1 -Name gruvbox -Apply -SetWindowsAccent
```

Supported themes currently include:

- `tokyo-night`
- `gruvbox`
- `ristretto`

Theme switching currently updates the repo-managed configs for komorebi,
komorebi bar, tacky-borders, Windows Terminal, VS Code, and Neovim.

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
.\scripts\install-software.ps1 -SkipCursors
.\scripts\install-software.ps1 -SkipVSCodeExtensions
```

The installer currently uses `winget` for the main apps/tools, downloads `tacky-borders` from the latest GitHub release because it does not currently have a winget package, downloads `CaskaydiaMono Nerd Font` from the latest Nerd Fonts release, and installs Bibata Modern Classic from the latest Bibata Cursor GitHub release.

Install or update only the cursor theme:

```powershell
.\scripts\install-bibata-cursor.ps1
```

Preview the cursor install:

```powershell
.\scripts\install-bibata-cursor.ps1 -WhatIf
```

Useful cursor variants:

```powershell
.\scripts\install-bibata-cursor.ps1 -Color Ice
.\scripts\install-bibata-cursor.ps1 -Color Amber
.\scripts\install-bibata-cursor.ps1 -Size Large
.\scripts\install-bibata-cursor.ps1 -Right
```

Current winget packages:

| Tool | Package ID |
| --- | --- |
| Git | `Git.Git` |
| PowerShell 7 | `Microsoft.PowerShell` |
| Visual Studio Code | `Microsoft.VisualStudioCode` |
| Zen Browser | `Zen-Team.Zen-Browser` |
| Flow Launcher | `Flow-Launcher.Flow-Launcher` |
| Everything | `voidtools.Everything` |
| Windows Terminal | `Microsoft.WindowsTerminal` |
| komorebi | `LGUG2Z.komorebi` |
| masir | `LGUG2Z.masir` |
| whkd | `LGUG2Z.whkd` |
| Starship | `Starship.Starship` |
| fzf | `junegunn.fzf` |
| zoxide | `ajeetdsouza.zoxide` |
| bat | `sharkdp.bat` |
| eza | `eza-community.eza` |
| ripgrep | `BurntSushi.ripgrep.MSVC` |
| fd | `sharkdp.fd` |
| delta | `dandavison.delta` |
| mise | `jdx.mise` |
| lazygit | `JesseDuffield.lazygit` |
| Neovim | `Neovim.Neovim` |

Manual follow-up still needed:

- Restart shells/apps after installing tools that update `PATH`.

## Wallpaper

Set the desktop wallpaper and attempt to set the lock screen image:

```powershell
.\scripts\set-wallpaper.ps1
```

Preview without changing anything:

```powershell
.\scripts\set-wallpaper.ps1 -WhatIf
```

Useful variants:

```powershell
.\scripts\set-wallpaper.ps1 -Style Fit
.\scripts\set-wallpaper.ps1 -SkipLockScreen
.\setup.ps1 -SkipWallpaper
```

The desktop wallpaper is applied per user. The lock screen uses Windows personalization policy registry keys, so that part may require administrator rights and can vary by Windows edition.
