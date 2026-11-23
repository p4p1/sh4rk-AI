# f0urm1

*It cost me 0.65$ to vibecode!*

> **The ant that saves the cicada's summer.**
> Full-fidelity scrollback archiver for tmux — every line ever rendered in
> every pane of every session, on disk before you close it all.

One file. Pure `bash` + the `tmux` binary. No plugins, no dependencies, no
setup. Drop it in your `PATH` and it's there when the engagement ends.

## The problem it solves

Long operations live in tmux. A week in, you have a dozen sessions and forty
panes — recon here, a foothold shell there, tunnels, loot folders, one-off
commands whose output never got redirected anywhere. The terminal record of
the whole engagement is spread across buffers you never close.

Then the engagement ends. `kill-server`, and weeks of terminal truth — every
command, every response, every answer you didn't pipe to a file — evaporates.

f0urm1 walks every session, every window, every pane and pulls the **entire
scrollback buffer** — from the top of history to the bottom of the screen,
not just what's visible — into a folder tree you can archive, grep, or hand
over as evidence.

## What you get

```
somefolder/
└── command_log/
    ├── manifest.txt               # pane -> tmux target map + metadata
    ├── recon/
    │   ├── pane01.txt             # full scrollback, ANSI stripped
    │   ├── pane02.txt
    │   └── pane03.alt.txt         # only if a fullscreen app was running
    ├── foothold/
    │   ├── pane01.txt
    │   └── pane02.txt
    └── loot/
        └── pane01.txt
```

- **`paneNN.txt`** — the complete scrollback of one pane, plain text. Panes
  are numbered in window/pane index order within each session; the manifest
  is the authoritative map from file to tmux target.
- **`paneNN.alt.txt`** — created only when a pane was running a fullscreen
  alt-screen app (`vim`, `less`, `htop`) at dump time. The normal capture
  still contains the shell history *behind* it; this preserves what the app
  was showing.
- **`manifest.txt`** — one row per pane: file, `session:window.pane` target,
  pane ID, window name, running command, working directory, pane title, dead
  status, captured line count, scrollback stats. Plus `WARNING` rows for
  panes whose scrollback hit its cap.

```text
captured	2026-11-23T14:02:11Z
host	p3ng0s-live
tmux	tmux 3.5a
file	tmux_target	pane_id	window	command	path	title	dead	lines	history
command_log/recon/pane01.txt	recon:0.0	%35	nmap	zsh	/home/p4p1-live/loot	nmap dom.corp	0	2043	2000/2000
WARNING	command_log/recon/pane01.txt	history full (2000/2000 lines) — older output was probably dropped
```

## Requirements

- `bash` ≥ 3.2 — no bash 4-isms; works even with macOS's fossil shell.
- `tmux` ≥ 2.6 recommended — every format variable used here (`history_size`,
  `history_limit`, `alternate_on`, …) has been in tmux's format table for
  years. On anything older, the affected manifest columns come back empty and
  the dump still runs.
- Linux, macOS, and Android (Termux) — same file everywhere. On Termux, run
  `termux-setup-storage` once if you want the tree under shared storage.

## Install

The script is the whole project:

```bash
chmod +x f0urm1
cp f0urm1 ~/.local/bin/     # or anywhere in your PATH
```

## Usage

```
f0urm1 [-e] [-r] [outdir]
```

| Flag / arg | Effect |
|------------|--------|
| `-e` | keep ANSI colours/attributes in the dumps (default: stripped for clean, greppable text) |
| `-r` | raw capture — exactly as displayed: wrapped lines stay split at pane width, trailing spaces preserved (default: wrapped lines are rejoined, so a 300-char command typed in an 80-col pane comes back as one line) |
| `outdir` | folder to create `command_log/` in (default: current directory) |

```bash
# the end-of-engagement ritual
f0urm1 ./acme-2026-11-23
tmux kill-server

# keep colours for the pretty copy
f0urm1 -e ./acme-2026-11-23

# byte-faithful to what the screen showed
f0urm1 -r ./acme-2026-11-23

# daily snapshots mid-engagement — re-runs just overwrite
f0urm1 ./acme-2026-11-23/$(date +%F)

# dump a named-socket server instead of the default
TMUX_CMD='tmux -L work' f0urm1 ./acme-2026-11-23
```

**Exit codes**

| Code | Meaning |
|------|---------|
| `0` | every pane dumped |
| `1` | usage error, no server, or no sessions |
| `2` | dump completed, but at least one pane had already hit its scrollback cap — older output was lost; check `manifest.txt` for the holes |

Notes:

- Run it from inside or outside tmux; it auto-detects the right server socket
  (including the one you're attached to, via `$TMUX`).
- It's read-only against tmux — reruns are safe, any time, as often as you
  like.
- If you run it from *inside* a pane, that pane's dump will include the
  script's own progress output. Cosmetic, and honestly kind of fitting.

## Read this before your next engagement

The whole premise — "the scrollback holds everything" — is bounded by tmux's
`history-limit`: **2000 lines per pane by default**, and the limit is baked
into a pane **at creation** — raising it later does nothing for panes that
already exist. A busy engagement pane blows through 2000 lines in a day.

Put this in `~/.tmux.conf` *before* you open the engagement sessions:

```text
set -g history-limit 500000
```

Scrollback lives in RAM per pane: 500k lines is nothing on a workstation;
on a phone, 100k is plenty.

f0urm1 refuses to let you believe a truncated record is a complete one: any
pane whose buffer is at capacity is flagged with exit code `2` and a
`WARNING` row in the manifest, so you know exactly where the holes are.

**Belt and braces** — tee every pane live to disk at engagement start; immune
to any scrollback cap:

```bash
mkdir -p ~/panes
tmux list-panes -a -F '#{pane_id}' | while IFS= read -r p; do
    tmux pipe-pane -o -t "$p" "cat >> $HOME/panes/${p}.log"
done
```

`pipe-pane` captures raw process output (even output that long scrolled out
of history); f0urm1 captures what the terminal actually rendered. Run both
and the record is genuinely complete.

## Design notes

- **Full history, not the visible screen.** `tmux capture-pane` defaults to
  grabbing only what's on screen. f0urm1 captures from the start of the
  scrollback buffer (`-S -`) through the bottom of the visible pane (`-E -`).
- **IDs, never names.** Panes are targeted by `pane_id` (`%N`) and sessions
  by `session_id` (`$N`) — unique and stable for the life of the object,
  immune to renames, glob characters and prefix collisions. Names are
  metadata, not addressing. This is also the tmux author's own recommendation
  ([tmux#2179](https://github.com/tmux/tmux/issues/2179)).
- **A real `0x1f` separator.** tmux does **not** expand `\t` in `-F` format
  strings passed from the shell — it emits a literal backslash-t (escape
  decoding only happens inside tmux's own config-file parser). Field
  separation uses an actual ASCII unit-separator byte, which cannot appear in
  any session, window, pane name, title or path. This was a real bug in the
  first draft; [tmux#2179](https://github.com/tmux/tmux/issues/2179) is the
  canonical reference.
- **Retroactive by design.** Logging plugins must be configured before the
  output happens. f0urm1 exists for the sessions you never prepared for
  logging — which is all of them, because you never planned to close them.
- **Built for mid-engagement reality.** A pane that dies between listing and
  capture, a fullscreen app exiting mid-dump, a session closing underneath
  the run — none of these abort anything. The affected pane is skipped with
  a warning, everything else still lands on disk, numbering stays dense, and
  the manifest only lists real captures.
- **Join or raw.** Default capture rejoins lines that wrapped at pane width;
  `-r` gives you the screen exactly as rendered, trailing spaces included.

## What it never does

- Writes no tmux state, sends nothing over the network, executes no pane
  content. It reads scrollback buffers and writes one folder tree — that's
  the entire interaction surface.
- No dependencies, no build, no updates to chase. One file to audit, and
  you can read all of it in ten minutes.

## Why the name

La Fontaine, *Fables*, Book I, Fable 1 — the very first one: the cicada
sings all summer and saves nothing, and when the north wind arrives she
begs the ant for grain. *"Vous chantiez ? j'en suis fort aise. Eh bien !
dansez maintenant."*

Every engagement lives in tmux panes that sing for weeks. This is the ant:
it drags every grain of that summer into the nest before winter — before
`kill-server` and the session's memory evaporates.

