# Rust TUI Guide

This guide is a working plan for building a Rust `omawin` CLI/TUI while keeping
the existing PowerShell scripts as the source of truth for machine-changing
behavior.

The target shape:

```powershell
omawin
omawin tui
omawin commands
omawin setup preview
omawin setup run
omawin config apply
omawin config collect
omawin desktop start
omawin desktop restart
omawin desktop status
omawin desktop logs
omawin wallpaper set
omawin theme list
omawin theme set tokyo-night --apply
```

Running `omawin` with no arguments should open the TUI. Direct commands should
remain available for scripts, hotkeys, troubleshooting, and future launcher
integrations.

## Product Direction

- Treat Omarchy as the reference for feel: keyboard-first, discoverable, and
  command-centered.
- Keep PowerShell scripts responsible for Windows automation.
- Use Rust for command discovery, argument parsing, TUI navigation, process
  launching, and better error reporting.
- Make the command registry the source of truth for both CLI subcommands and
  TUI menu entries.
- Avoid adding a GUI until the CLI/TUI command model feels stable.

## Suggested Crate Layout

Start with a crate under `tools\omawin`:

```text
tools\omawin\
  Cargo.toml
  src\
    main.rs
    app.rs
    commands.rs
    repo.rs
    runner.rs
    tui.rs
```

Possible responsibilities:

```text
main.rs       Parse CLI args and route to TUI or direct command execution.
commands.rs   Define command groups, labels, script mappings, and risk levels.
repo.rs       Resolve the omawin repo root.
runner.rs     Invoke PowerShell scripts and stream output.
tui.rs        Own terminal setup, event loop, drawing, and input handling.
app.rs        Store selected item, search query, current screen, and output state.
```

## Todo List

- [ ] Create the Rust crate under `tools\omawin`.
- [ ] Add `clap`, `ratatui`, `crossterm`, `anyhow`, and `serde`.
- [ ] Implement repo root resolution.
- [ ] Implement a static command registry.
- [ ] Implement direct commands for the current `bin\omawin.ps1` routes.
- [ ] Make `omawin` with no args open the TUI.
- [ ] Build a first TUI screen with grouped commands.
- [ ] Add keyboard navigation: `j/k`, arrow keys, `Enter`, `Esc`, `q`, `/`.
- [ ] Add command search/filtering.
- [ ] Add confirmation prompts for risky commands.
- [ ] Stream script output into an output screen.
- [ ] Return the script exit code for direct commands.
- [ ] Add `omawin commands` and later `omawin commands --json`.
- [ ] Update `scripts\apply-configs.ps1` to install the compiled binary when
  the first version is ready.
- [ ] Update `readme.md` once the Rust CLI replaces the PowerShell router as
  the public command surface.
- [ ] Update `config\whkd\whkdrc` later to open `omawin` in Windows Terminal.

## Useful Cargo Commands

Create the crate:

```powershell
mkdir tools
cargo new tools\omawin --bin
```

Work inside the crate:

```powershell
cd tools\omawin
cargo check
cargo run
cargo run -- commands
cargo run -- desktop status
cargo fmt
cargo clippy --all-targets -- -D warnings
cargo test
cargo build --release
```

Run from the repo root without changing directories:

```powershell
cargo run --manifest-path tools\omawin\Cargo.toml -- tui
cargo run --manifest-path tools\omawin\Cargo.toml -- setup preview
cargo build --manifest-path tools\omawin\Cargo.toml --release
```

Install locally during development:

```powershell
cargo install --path tools\omawin --force
```

## Initial Dependencies

`tools\omawin\Cargo.toml`:

```toml
[package]
name = "omawin"
version = "0.1.0"
edition = "2021"

[dependencies]
anyhow = "1"
clap = { version = "4", features = ["derive"] }
crossterm = "0.28"
ratatui = "0.29"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

## CLI Skeleton

This shape keeps `omawin` as the TUI entry point while still supporting direct
subcommands.

```rust
use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod repo;
mod runner;
mod tui;

#[derive(Debug, Parser)]
#[command(name = "omawin")]
#[command(about = "Windows desktop setup command center")]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Open the terminal UI.
    Tui,

    /// Print available commands.
    Commands {
        /// Emit machine-readable JSON.
        #[arg(long)]
        json: bool,
    },

    /// Setup commands.
    Setup {
        #[command(subcommand)]
        command: SetupCommand,
    },

    /// Config commands.
    Config {
        #[command(subcommand)]
        command: ConfigCommand,
    },

    /// Desktop stack commands.
    Desktop {
        #[command(subcommand)]
        command: DesktopCommand,
    },
}

#[derive(Debug, Subcommand)]
enum SetupCommand {
    Preview,
    Run,
}

#[derive(Debug, Subcommand)]
enum ConfigCommand {
    Apply,
    Collect,
}

#[derive(Debug, Subcommand)]
enum DesktopCommand {
    Start,
    Restart,
    Status,
    Logs,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let repo_root = repo::resolve_repo_root()?;

    match cli.command {
        None | Some(Command::Tui) => tui::run(&repo_root),
        Some(Command::Commands { json }) => commands::print_commands(json),
        Some(command) => runner::run_cli_command(&repo_root, command),
    }
}
```

## Command Registry Sketch

Start static. Metadata scanning can come later.

```rust
use serde::Serialize;

#[derive(Debug, Clone, Copy, Serialize)]
pub enum Risk {
    ReadOnly,
    ChangesRepo,
    ChangesMachine,
}

#[derive(Debug, Clone, Serialize)]
pub struct OmawinCommand {
    pub id: &'static str,
    pub group: &'static str,
    pub label: &'static str,
    pub summary: &'static str,
    pub script: &'static str,
    pub args: &'static [&'static str],
    pub risk: Risk,
}

pub const COMMANDS: &[OmawinCommand] = &[
    OmawinCommand {
        id: "setup.preview",
        group: "Setup",
        label: "Preview full setup",
        summary: "Run setup.ps1 with -WhatIf.",
        script: "setup.ps1",
        args: &["-WhatIf"],
        risk: Risk::ReadOnly,
    },
    OmawinCommand {
        id: "config.apply",
        group: "Config",
        label: "Apply repo configs",
        summary: "Copy repo configs into the current user profile.",
        script: "scripts\\apply-configs.ps1",
        args: &[],
        risk: Risk::ChangesMachine,
    },
    OmawinCommand {
        id: "desktop.restart",
        group: "Desktop",
        label: "Restart desktop stack",
        summary: "Restart komorebi, whkd, masir, bar, and borders.",
        script: "scripts\\start-desktop.ps1",
        args: &["-Restart"],
        risk: Risk::ChangesMachine,
    },
];

pub fn print_commands(json: bool) -> anyhow::Result<()> {
    if json {
        println!("{}", serde_json::to_string_pretty(COMMANDS)?);
    } else {
        for command in COMMANDS {
            println!("{:<18} {}", command.id, command.summary);
        }
    }

    Ok(())
}
```

## Repo Root Resolution

Resolution order should be predictable:

1. `OMAWIN_REPO`
2. `%USERPROFILE%\.config\omawin\repo-root.txt`
3. Walk up from the current directory until `setup.ps1` is found

```rust
use anyhow::{bail, Context, Result};
use std::{env, fs, path::PathBuf};

pub fn resolve_repo_root() -> Result<PathBuf> {
    if let Some(path) = env::var_os("OMAWIN_REPO") {
        let path = PathBuf::from(path);
        if path.join("setup.ps1").is_file() {
            return Ok(path);
        }
    }

    if let Some(home) = env::var_os("USERPROFILE") {
        let marker = PathBuf::from(home).join(".config\\omawin\\repo-root.txt");
        if marker.is_file() {
            let path = PathBuf::from(fs::read_to_string(&marker)?.trim());
            if path.join("setup.ps1").is_file() {
                return Ok(path);
            }
        }
    }

    let mut dir = env::current_dir().context("failed to get current directory")?;
    loop {
        if dir.join("setup.ps1").is_file() {
            return Ok(dir);
        }

        if !dir.pop() {
            break;
        }
    }

    bail!("could not find omawin repo root");
}
```

## Script Runner

Prefer `pwsh`, fall back to Windows PowerShell. Direct commands should inherit
stdio so script output feels native.

```rust
use anyhow::{bail, Context, Result};
use std::{
    path::Path,
    process::{Command, Stdio},
};

pub fn run_script(repo_root: &Path, script: &str, args: &[&str]) -> Result<i32> {
    let script_path = repo_root.join(script);
    if !script_path.is_file() {
        bail!("script not found: {}", script_path.display());
    }

    let shell = if command_exists("pwsh") {
        "pwsh"
    } else {
        "powershell.exe"
    };

    let status = Command::new(shell)
        .arg("-NoProfile")
        .arg("-ExecutionPolicy")
        .arg("Bypass")
        .arg("-File")
        .arg(&script_path)
        .args(args)
        .current_dir(repo_root)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .with_context(|| format!("failed to run {}", script_path.display()))?;

    Ok(status.code().unwrap_or(1))
}

fn command_exists(name: &str) -> bool {
    Command::new(name)
        .arg("-NoProfile")
        .arg("-Command")
        .arg("$PSVersionTable.PSVersion.ToString()")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok()
}
```

## TUI App State

Keep state small at first.

```rust
use crate::commands::OmawinCommand;

pub struct App {
    pub commands: Vec<OmawinCommand>,
    pub selected: usize,
    pub search: String,
    pub mode: Mode,
}

pub enum Mode {
    Browsing,
    Searching,
    Confirming,
    Running,
}

impl App {
    pub fn new(commands: Vec<OmawinCommand>) -> Self {
        Self {
            commands,
            selected: 0,
            search: String::new(),
            mode: Mode::Browsing,
        }
    }

    pub fn next(&mut self) {
        if !self.commands.is_empty() {
            self.selected = (self.selected + 1).min(self.commands.len() - 1);
        }
    }

    pub fn previous(&mut self) {
        self.selected = self.selected.saturating_sub(1);
    }
}
```

## TUI Event Loop Sketch

Use this as a shape reference, not final code.

```rust
use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};
use std::{io, path::Path};

pub fn run(repo_root: &Path) -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    let result = run_inner(repo_root, &mut terminal);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    result
}

fn run_inner(
    _repo_root: &Path,
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
) -> Result<()> {
    loop {
        terminal.draw(|frame| {
            // Draw command list, search bar, status line, and help footer here.
            let _ = frame;
        })?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') | KeyCode::Esc => break,
                KeyCode::Char('j') | KeyCode::Down => {
                    // app.next()
                }
                KeyCode::Char('k') | KeyCode::Up => {
                    // app.previous()
                }
                KeyCode::Enter => {
                    // confirm or run selected command
                }
                KeyCode::Char('/') => {
                    // enter search mode
                }
                _ => {}
            }
        }
    }

    Ok(())
}
```

## First TUI Screen

Keep the first screen dense and functional:

```text
omawin

Setup
  Preview full setup
  Run full setup

Desktop
  Start stack
  Restart stack
  Status
  Logs

Config
  Apply repo configs
  Collect live configs

Theme
  List themes
  Apply tokyo-night
  Apply gruvbox
  Apply ristretto

Wallpaper
  Set default wallpaper

/ search   Enter run   q quit
```

## Command Safety Rules

- Read-only commands can run immediately.
- Machine-changing commands should ask for confirmation in the TUI.
- Direct CLI commands should not prompt unless the underlying script already
  does. They should behave like normal command-line tools.
- Keep script `-WhatIf` behavior exposed as preview commands.
- Never hide script failures. Show the exit code and the relevant output.

## Whkd Integration Later

Once the TUI works, the hotkey should open it in Windows Terminal instead of a
hidden PowerShell window:

```text
win + alt + space : Start-Process wt -ArgumentList "omawin"
```

If `omawin` is not on `PATH`, point the binding at the installed binary or a
small `.cmd` shim under `%USERPROFILE%\.config\omawin\bin`.

## Good First Milestone

The first useful milestone is small:

- `cargo run --manifest-path tools\omawin\Cargo.toml` opens a terminal UI.
- The TUI lists static commands.
- `q` exits cleanly and restores the terminal.
- `Enter` runs `desktop status`.
- `cargo run --manifest-path tools\omawin\Cargo.toml -- desktop status` works
  without opening the TUI.

After that, add search, confirmations, output panes, themes, and install wiring.
