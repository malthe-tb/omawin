# Roadmap

This file tracks product direction and rough priorities. Keep implementation
details in the scripts or architecture notes; use this file to decide what the
setup should become next.

## Now

- Tighten the default desktop shell: `komorebi`, `whkd`, `masir`, and
  `tacky-borders` should feel like one integrated environment.
- Setup missing essential software `WSL`
- Expand the `omawin` command router and keyboard menu into the main command
  surface for daily desktop actions.
- Improve the theme and styling story by translating Omarchy's theme model to
  Windows-native targets such as komorebi bar, Windows Terminal, VS Code,
  PowerShell, wallpaper, cursor, and borders.
- Make the install/apply/collect scripts more consistent, especially around
  `-WhatIf`, backups, logs, and fresh-machine expectations.
- Document visible differences from Omarchy where Windows requires a different
  implementation.

## Next

- Add a richer `omawin` TUI or Flow Launcher integration for common workflows:
  setup checks, config apply/collect, desktop stack inspection, theme or
  wallpaper switching, and access to relevant logs and config files.
- Add stronger terminal ergonomics after install, including aliases/functions
  for the installed CLI tools where PowerShell needs explicit wiring.
- Improve the top bar/status experience so it follows the chosen visual style
  and exposes useful window-manager/system state. The built-in komorebi bar is
  now the default bar surface.
- Add a clearer Caps Lock or leader-key workflow for window navigation,
  launcher access, terminal access, and common desktop actions.

## Later

- Build a fuller GUI `omawin` app if the menu/router proves useful and the
  workflows are clear.
- Add WSL setup once the Windows-native base is solid.
- Expand the LazyVim-based Neovim setup, with deliberate integration points for
  VS Code rather than treating them as separate worlds.
- Investigate config linking or sync workflows so changes made in apps can be
  captured without manual collection every time.

## Open Questions

- Should `omawin` be primarily a script launcher, a configuration inspector, or
  a higher-level state manager?
- Should themes be a single repo-level concept, or should each app keep its own
  independent config with a shared palette?
- Should optional developer stacks, such as embedded systems tooling, live in
  this repo or in separate role-specific setup scripts (vkpkg)?
- How much should this repo automate Windows settings that are fragile,
  edition-specific, or hard to reverse?

## Omarchy Parity Targets

- Theme switching across shell, terminal, editor, status bar, wallpaper, and
  lock/login-adjacent surfaces where Windows exposes a reliable equivalent.
- Keyboard-first launch, focus, tiling, workspace, screenshot, and system
  workflows.
- A small command surface similar in spirit to Omarchy's `omarchy-*` helpers,
  translated to PowerShell and Windows conventions.
- A polished first-run path that leaves the machine in a coherent default state
  instead of a collection of installed tools.
