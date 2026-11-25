<img src="/res/sh4rk-logo.png" width="500" />

sh4rk-AI
========

My AI playground. **Vibe code only** — everything in here was built by
chatting with an AI. no objectives, no roadmap, no CI. If it works, it ships.

## The idea

One repo for all the AI things I make:

 - **`vibe/`** — little vibecoded tools. one folder per tool, each with a
   thorough README. pentest helpers, webshells, tmux tricks, browser
   tunnels — whatever the AI and I felt like building that day.
 - **`skills/`** — AI skills: system prompts / agent definitions I write and
   reuse, like `report-writter.md` (a senior pentester report-writer agent).
 - **`template/`** — `master_prompt.md`, the canonical template every new
   skill is built from.
 - **`res/`** — logo and friends.

## The vibe tax

Every vibecoded tool carries its price tag in its own README — the
*"It cost me X$ to vibecode!"* line. This repo doubles as my ledger of what
an AI actually charges to turn a conversation into a working tool.

| Tool | Vibe tax | What it is |
|---|---|---|
| [`vibe/aspx-webshell`](vibe/aspx-webshell/) | 0.30$ | single-file ASPX command console for IIS |
| [`vibe/aspx-webshell (hacker elite version)`](vibe/aspx-webshell/) | 0.09$ | the cringe edition of the same shell |
| [`vibe/ilo-probe`](vibe/ilo-probe/) | 0.14$ | lockout-safe unauthenticated HPE iLO fleet recon |
| [`vibe/tmux-foumri`](vibe/tmux-foumri/) | 0.65$ | full-fidelity tmux scrollback archiver |
| [`vibe/undertow`](vibe/undertow/) | 3.35$ | invisible extension + native host that drags a reverse SOCKS5 tunnel to your chisel server |
| **Total** | **4.53$** | |
