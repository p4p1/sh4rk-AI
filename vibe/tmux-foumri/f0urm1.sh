#!/usr/bin/env bash
#
# f0urm1.sh — dump the full scrollback of every pane of every tmux session.
#
# Output:
#   <outdir>/command_log/<session>/paneNN.txt        full pane history, plain text
#   <outdir>/command_log/<session>/paneNN.alt.txt    alt-screen copy (only if a fullscreen
#                                                     app like vim/less/htop is running)
#   <outdir>/command_log/manifest.txt                pane -> tmux target map + metadata
#
# Usage:
#   ./tmux-dump.sh [-e] [-r] [outdir]
#     -e      keep ANSI colours in the dumps (default: stripped)
#     -r      raw: capture exactly as displayed (wrapped lines stay split)
#     outdir  folder to create command_log/ in (default: current dir)
#
#   TMUX_CMD='tmux -L work' ./tmux-dump.sh    # dump a named-socket server
#
# Exit codes: 0 ok | 1 error | 2 dumped, but some panes had hit their
# history-limit, meaning older output was already gone (check manifest.txt).
#
# IMPORTANT: scrollback is capped per pane by 'history-limit' (default 2000
# lines!), fixed at pane creation. For engagement-length sessions, put this in
# ~/.tmux.conf BEFORE opening the sessions:
#     set -g history-limit 500000

set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*" >&2; }

ansi=0 raw=0
while getopts ":er" opt; do
    case $opt in
        e) ansi=1 ;;
        r) raw=1 ;;
        *) die "usage: $0 [-e] [-r] [outdir]" ;;
    esac
done
shift $((OPTIND - 1))

command -v tmux >/dev/null 2>&1 || die "tmux not found in PATH"

# Pick the server: TMUX_CMD overrides; otherwise the socket of the session we're
# running inside ($TMUX = "socket,pid,session"); otherwise the default socket.
read -r -a tcmd <<<"${TMUX_CMD:-tmux}"
if [ "${TMUX_CMD:-tmux}" = tmux ] && [ -n "${TMUX:-}" ]; then
    sock=${TMUX%%,*}
    [ -S "$sock" ] && tcmd=(tmux -S "$sock")
fi

# Field separator for tmux -F output: a REAL control character (ASCII unit
# separator, 0x1f), embedded as an actual byte — NOT "\t" in the format string,
# which tmux passes through as a literal backslash-t since it only decodes
# escapes in its own config/command-prompt parser. Cannot appear in any
# session/window/pane name, title or path. read splits on it via IFS.
sep=$'\037'

# Sessions as stable IDs + names; every target below uses IDs ($N / %N), never names.
sessdata=$("${tcmd[@]}" list-sessions -F "#{session_id}${sep}#{session_name}" 2>/dev/null) \
    || die "no tmux server or no sessions running"

outdir=${1:-.}
root=$outdir/command_log
mkdir -p "$root"

{
    printf 'captured\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'host\t%s\n' "$(uname -n)"
    printf 'tmux\t%s\n' "$("${tcmd[@]}" -V)"
    printf 'file\ttmux_target\tpane_id\twindow\tcommand\tpath\ttitle\tdead\tlines\thistory\n'
} >"$root/manifest.txt"

seen_names=$sep
total=0 skipped=0 flagged=0
while IFS="$sep" read -r sid sess; do
    [ -n "$sid" ] || continue

    # Filesystem-safe dir name: no '/', no control chars, no '.'/'..'
    sname=${sess//\//_}
    sname=${sname//$sep/_}
    sname=${sname//$'\t'/_}
    sname=${sname//$'\n'/_}
    case $sname in ''|.|..) sname="_$sname" ;; esac
    # Two sessions sanitizing to the same dir name? disambiguate with the session ID
    if [[ $seen_names == *"${sep}${sname}${sep}"* ]]; then
        sname="${sname}~${sid#\$}"
    fi
    seen_names="${seen_names}${sname}${sep}"
    sdir=$root/$sname
    mkdir -p "$sdir"

    n=0
    while IFS="$sep" read -r pid win wname pidx pcmd ppath ptitle dead alton hsize hlimit; do
        case $pid in
            '%'*) ;;
            *) say "  ! '$sess': skipping malformed pane line: $pid"
               skipped=$((skipped + 1)); continue ;;
        esac

        printf -v fname 'pane%02d.txt' "$((n + 1))"

        # The money shot: from the start of history (-S -) to the bottom of the screen
        cap=(capture-pane -p -t "$pid" -S - -E -)
        if [ "$ansi" = 1 ]; then cap+=(-e); fi
        if [ "$raw" = 1 ]; then cap+=(-N); else cap+=(-J); fi   # -J = join wrapped lines
        if ! "${tcmd[@]}" "${cap[@]}" >"$sdir/$fname" 2>/dev/null; then
            say "  ! '$sess': capture failed for pane $pid (died mid-dump?) — skipping"
            rm -f "$sdir/$fname"
            skipped=$((skipped + 1))
            continue
        fi
        n=$((n + 1)); total=$((total + 1))
        fpath=$sdir/$fname

        # Fullscreen app currently on the alt screen? save its view too
        if [ "$alton" = 1 ]; then
            alt=(capture-pane -p -q -a -t "$pid")
            if [ "$ansi" = 1 ]; then alt+=(-e); fi
            if ! "${tcmd[@]}" "${alt[@]}" >"${fpath%.txt}.alt.txt" 2>/dev/null; then
                rm -f "${fpath%.txt}.alt.txt"    # alt screen vanished mid-dump; not fatal
            fi
        fi

        # Keep manifest columns intact even if a title contains a tab
        wname=${wname//$'\t'/ }
        ppath=${ppath//$'\t'/ }
        ptitle=${ptitle//$'\t'/ }

        lines=$(wc -l <"$fpath")
        printf '%s\t%s:%s.%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s/%s\n' \
            "command_log/$sname/$fname" "$sess" "$win" "$pidx" "$pid" "$wname" \
            "$pcmd" "$ppath" "$ptitle" "$dead" "$lines" "$hsize" "$hlimit" \
            >>"$root/manifest.txt"

        # Buffer at capacity => oldest lines were already thrown away
        if [ -n "$hsize" ] && [ "$hsize" = "$hlimit" ] && [ "$hsize" != 0 ]; then
            flagged=$((flagged + 1))
            printf 'WARNING\t%s\thistory full (%s/%s lines) — older output was probably dropped\n' \
                "command_log/$sname/$fname" "$hsize" "$hlimit" >>"$root/manifest.txt"
            say "  ! $sess:$win.$pidx hit its history-limit ($hsize lines) — old output was lost"
        fi
    done < <("${tcmd[@]}" list-panes -s -t "$sid" -F \
        "#{pane_id}${sep}#{window_index}${sep}#{window_name}${sep}#{pane_index}${sep}#{pane_current_command}${sep}#{pane_current_path}${sep}#{pane_title}${sep}#{pane_dead}${sep}#{alternate_on}${sep}#{history_size}${sep}#{history_limit}")

    say "session '$sess': $n pane(s) -> $sdir"
done <<<"$sessdata"

say "done: $total pane(s) dumped, $skipped skipped, $flagged truncated"
say "manifest: $root/manifest.txt"
if [ "$flagged" -gt 0 ]; then exit 2; fi

