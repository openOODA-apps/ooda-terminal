# openOODA (.oo) Agent Quick Card for openOODA-apps/ooda-console v0.1.0
1. **The 8 Canonical Quick Cards** (Zero-bloat ~24-line cards built into `ooda`):
   - `ooda ooda`     -> `ooda.md`     (How to rapidly build, test, and adapt openOODA software)
   - `ooda layers`   -> `layers.md`   (The 8-Layer Architecture Map `L0`–`L7` across Desktop, Server & Mobile)
   - `ooda spec`     -> `spec.md`     (`.oo` syntax, types, structs, `match`, and `ooda-standard` builtins)
   - `ooda rules`    -> `rules.md`    (Power-of-2 Shape Ladder `1/2/4/8/16/32/64/128/256` & CLI laws)
   - `ooda ui`       -> `ui.md`       (CLI, TUI, Desktop & Mobile UI + `ooda-theme` 25 presets & 34 tokens)
   - `ooda security` -> `security.md` (Zero-Trust `CapReg64` `0..31` caps, `ooda-sandbox`, `ooda-sign`, `ooda-provenance`, `ooda-vault`)
   - `ooda privacy`  -> `privacy.md`  (Zero-telemetry, PII/EXIF/SECRET scrubbing `ooda-redact`, LED & clipboard TTL gates)
   - `ooda defense`  -> `defense.md`  (Active defense `ooda-defense` IDS/canary/honeypot, `ooda-firewall`, DMA/DRAM/USB guards)
2. **Power-of-2 Shape Ladder (`1/2/4/8/16/32/64/128/256`)**:
   - `1`: Link count == 1 (0 symlinks/hardlinks) & max 1 statement/line. `2`: Lean 2-file `tests/` suite (`tests/test_functional.oo` + `tests/test_refusal.oo`, 0 source-grepping) plus the `tests/emit_vt.oo` fixture helper.
   - `4`: Max 4 nesting depth & **4-Axis Code Review** (`1. ooda-verify Gate` + `2. Semantic Logic & Spec` + `3. Native Binary & Systems` + `4. Ecosystem & Registry`). `8`: Max 8 files/dir, 8 fns/file, 8 params/fn, & 8-entry repo root (`AGENTS.md`, `README.md`, `Makefile`, `ooda.pkg`, `anchor.oo`, `cli/`, `core/`, `tests/`). `16`: Min 16 lines/file.
   - `32`: 32 explicit capabilities (`&FsReadCap`, `&FsWriteCap`, `&NetCap`, `&ProcessCap`, `&EnvCap`), max 32 chars/name (no `*_1.oo` splits), <=32 files/repo.
   - `64`: Max 64 code lines/fn. `128`: Max 128 chars/line. `256`: Max 256 lines/file.
3. **Syntax, Mandatory `ooda-standard` Reuse & Workflow**:
   - Relative string imports only (`import "core/session.oo";` or `import "ooda-standard/core/app/ui/term/anchor.oo";`, never `::`). No parens on `if cond { }` / `while cond { }`. No struct trailing commas. Connect all CLI/TUI/GUI output to `ooda-theme` and expose `<binary> about`.
   - **The VT500 engine is never re-implemented here.** The parser, the grid, the screen semantics, the pixel raster, and the replay session live in `ooda-standard/core/app/ui/term` and are imported as `ooda-standard/core/app/ui/term/...`. The portability gate refuses `/dev/ptmx`, `/dev/pts/`, `/dev/tty`, and `ioctl`/`termios` plumbing in a `layer=apps` package, so the pty host must be the capability-gated `ooda-standard/fs/os/host_grp/host_pty.oo` page, never a local device path.
   - Build & Verify: `ooda build && ooda test && ooda check && ooda audit`.
4. **This app**: ooda-console v0.1.0, org openOODA-apps, layer apps. Transcript replay, live pty child, desktop window, theme, about. Capabilities FsRead, FsWrite, Fs, Process, Env, Ffi.

## Capability Justification

| Capability | Why this app needs it |
|---|---|
| `Process` | Spawn the child under the pty (`oo_host_pty_open` / `oo_host_pty_spawn` / `oo_host_pty_read` / `oo_host_pty_write` / `oo_host_pty_close`). |
| `FsRead` | Read the console configuration file. |
| `FsWrite` | The shared Wayland page writes the socket and the shm buffer descriptors (`wl_win_open(fs, fw, env, ffi, ...)`). |
| `Fs` | The shared Wayland page opens the display socket and the shm files under `&FsCap`. |
| `Env` | `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` discovery under `&EnvCap`. |
| `Ffi` | The shared Wayland window and the shared text blitter are `&FfiCap` gated (`wl_win_open`, `wl_win_poll`, `ui_text_draw`). |
| `Frame` | **Not claimed.** The compositor owns the physical surface and holds `FrameCap`; a client binds to it through the sealed handle, exactly like the system-layer terminal, and the shared Wayland window owns its own client surface. |

## Known Limits

- **GAP-1 — no keyboard path in the shared engine.** The engine in `ooda-standard/core/app/ui/term` is pure: it has no keyboard input API and no pty write path. This app binds the keyboard itself — `wl_win_poll` yields a `UiEvent` with `kind == 7`, `ui_evdev_action(ev.key)` names the key, and `console_key_bytes` turns it into the bytes a child expects, which are written with `oo_host_pty_write`. That binding lives in this package, not in the engine.
- **GAP-2 — no Alt or Super modifier tracking.** `UiEvent` carries no modifier state, and `WlWindow` tracks only `shift_held` and `ctrl_held`. A chorded Alt or Super key cannot be distinguished from its base key, so the console forwards only the base key.
- **GAP-3 — no compositor surface handover.** No transport issues a compositor surface token, so `ooterm_surface_new` and `present_admit` have no production caller. The console draws into its own Wayland window and does not use the compositor surface admission path.
- **GAP-4 — the window path is not exercised headlessly.** The suite proves the engine, the pty child, the row runs, the key mapping, and the configuration; the Wayland draw is a thin binding that needs a live display.
