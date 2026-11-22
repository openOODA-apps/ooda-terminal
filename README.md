# ooda-console

Apps-layer GUI terminal front end for openOODA-apps. It runs a child in a PTY and renders its VT500 output through the shared ooda-standard terminal engine.

- Version: 0.1.0
- Subcommands: run, pty-run, gui, theme, inspect, status, verify, about
- Capabilities: FsRead, FsWrite, Fs, Process, Env, Ffi
- Layer: apps

## Usage

```sh
ooda-console pty-run ./my-program
ooda-console run transcript.txt
ooda-console gui ./my-program
ooda-console about
ooda-console about --json
```

`pty-run` spawns the child under a PTY, drains its bytes into the shared engine, and prints the interpreted screen.
`gui` opens the desktop window, draws the styled grid every frame, and forwards the key events to the child.
Unknown flags, unknown `about` targets, and missing operands exit 2.

## The engine is shared, never re-implemented

The VT500 parser, the cell grid, the screen semantics, the pixel raster, and the replay session live in
`ooda-standard/core/app/ui/term` and are imported as `ooda-standard/core/app/ui/term/...`. This package owns the
front end only: the pty child, the styled row runs, the surface binding, and the configuration.

## Build and Test

```sh
make clean all test det
```

Build uses ooda-compiler from ~/.openooda and resolves ooda-standard from the sibling source checkout.
Binary lands in bin/ooda-console.

## Known gaps

The keyboard binding, the modifier limits, and the compositor surface handover are recorded in AGENTS.md.
