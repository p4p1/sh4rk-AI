# AGENTS.md

Personal playground repo for AI stuff. No real objective — master prompts, AI skill definitions, vibecoded tools. That is all.

## Repo layout

| Path | What it is |
|---|---|
| `skills/` | AI skill / system-prompt definitions (one `.md` file per skill). e.g. `skills/report-writter.md` is a senior pentester report-writer agent. |
| `template/` | `master_prompt.md` — the canonical template for building new prompts/skills (context, coding conventions, project sections, constraints). New skills should follow its structure. |
| `vibe/` | Vibecoded tools. One folder per tool, each with its own `README.md` + source. Existing: `aspx-webshell`, `ilo-probe`, `tmux-foumri`. |
| `res/` | Logo and other assets. |
| `claude/` | **Gitignored personal backup folder. Ignore it entirely. Do not read, edit, or reference anything in there.** |

## Content domain

Most content here is offensive-security oriented (red teaming, pentest tooling, webshells, recon). Everything is lab / authorized-engagement material — treat it accordingly and keep the "authorized targets only" framing that the existing tools carry.

## Conventions

- New skill file → `skills/<name>.md`, structured like `template/master_prompt.md` (Who you are → Coding convention → Who you are talking to → The project → Constraints). See `skills/report-writter.md` for a filled-in example.
- New vibe project → `vibe/<name>/` with a thorough `README.md` (look at existing ones: usage, options, output, operational notes, legal note). Fun title + "It cost me X$ to vibecode!" tagline is the house style.
- **C coding style** (from the template, applies to any C project here):
  - Never `goto`, ever. Proper return-case management instead.
  - No `typedef` — not for structs, not for function pointers. Everything inline and explicit.
  - Align function names, variables, and return status at the same indent level (see the snippet in `template/master_prompt.md`).
  - Condense code into tight logic blocks; avoid sprawling functions.
  - No `switch/case` unless obviously the better solution; no big if/else forests.
  - Max 2 nested loops — beyond that, split into functions.
- Bash projects: pure `bash` + the target binary, no plugins/deps, single file preferred (see `vibe/tmux-foumri`).
- Python projects: stdlib only unless there's a real reason not to be (see `vibe/ilo-probe`).

## Git

- Commit messages are casual and lowercase — `lol new vibez`, `wow`, `cool new pentest reports`. Match the energy.
- Don't commit anything into `claude/` (it's gitignored for a reason).
- No CI, no lint setup, no tests framework — it's a playground. Verify scripts by running them.
