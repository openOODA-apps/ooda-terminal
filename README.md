# ooda-terminal

Apps-layer terminal for openOODA-apps. It turns a program's byte stream into a character grid: a windowed front end, a
headless replay verb, a live child verb, kitty and sixel graphics, OSC 133 shell integration, tabs and splits, and
configuration.

- Version: 1.1.0
- Subcommands: run, pty-run, gui, --app, tui-apps, theme-sync, theme, inspect, status, verify, about
- Capabilities: FsRead, FsWrite, Fs, Process, Env, Ffi
- Layer: apps

## Usage

```sh
ooda-terminal pty-run ./my-program
ooda-terminal run transcript.txt
ooda-terminal gui ./my-program
ooda-terminal about
ooda-terminal about --json
```

`pty-run` spawns the child under a PTY, drains its bytes into the shared engine, and prints the interpreted screen.
`gui` opens the desktop window, draws the styled grid every frame, and forwards the key events to the child.
Unknown flags, unknown `about` targets, and missing operands exit 2.

## Layout

- `cli/` — the product surface: argument parsing and the palette, the about card, the `run` and `pty-run` verbs, and the
  desktop window.
- `core/` — the domain: the replay session over the shared engine, the PTY child, the styled row runs, the surface
  binding, and the configuration.
- `core/gfx/` — the graphics protocols: the decoded image buffer, the placement into the cell grid, the kitty parser,
  the sixel palette, and the sixel raster.
- `core/marks/` — the OSC 133 shell integration: the boundary markers, the prompt state machine, the exit status, and the
  screen state that binds them.
- `core/tabs/` — the tabs and splits: the tab, the split tree, the layout geometry, and the tab set.

## The engine is shared, never re-implemented

The VT500 parser, the cell grid, the screen semantics, the pixel raster, and the replay session live in
`ooda-standard/core/app/ui/term` and are imported as `ooda-standard/core/app/ui/term/...`. This package owns the
product: the windowed front end, the headless verbs, and the terminal's own features.

## Build and Test

```sh
make clean all test det
```

Build uses ooda-compiler from ~/.openooda and resolves ooda-standard from the installed standard under ~/.openooda,
falling back to the sibling source checkout. Binary lands in bin/ooda-terminal.

## Known gaps

The keyboard binding, the modifier limits, and the compositor surface handover are recorded in AGENTS.md.
