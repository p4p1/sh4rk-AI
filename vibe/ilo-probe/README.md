# ilo_probe

It cost me 0.14$ to vibecode!

Unauthenticated recon tool for HPE iLO management interfaces (BMC fleet triage).
ilo_probe pulls the two endpoints that iLO serves without authentication —
`/redfish/v1/` and `/xmldata?item=all` — extracts firmware version, hardware
identity, and the IPMI-over-LAN state, then classifies each target against a
table of known iLO CVE ranges. Results can be exported to CSV for quick triage
of what machine has what.
It is lockout-safe by construction: the tool **never sends credentials** —
no `POST /Sessions`, no IPMI authentication attempts — so it can be run
against an entire fleet without touching an account lockout counter.

## Why
Out-of-band management controllers are routinely forgotten during patching and
frequently sit on the same flat network as corporate users. iLO exposes
meaningful information — firmware version, server serials, internal FQDNs,
NIC inventory, IPMI state — to **any unauthenticated GET**. ilo_probe turns
that disclosure into an actionable fleet-wide assessment in seconds.
Typical output of a sweep answers three questions immediately:
1. Which BMCs run firmware inside a known CVE range?
2. Which BMCs have IPMI over LAN enabled (UDP 623 attack surface)?
3. Is the management plane reachable from where you're standing at all?
   (If yes, that itself is a segmentation finding.)

## Requirements
- Python 3.8+
- Standard library only (argparse, json, ssl, csv, urllib, ElementTree).
  No external dependencies.

## Usage
single target

```
./ilo_probe.py -ip 172.17.3.142
```

fleet sweep from a file, results to CSV
```
./ilo_probe.py -f targets.txt -o results.csv
```

fast sweep, short timeout
```
./ilo_probe.py -f targets.txt --threads 20 --timeout 5 -o results.csv
```

### Options
| Option | Description |
|---|---|
| `-ip HOST` | Probe a single IP or hostname. |
| `-f FILE` | Target list, one host per line. `#` starts a comment. |
| `-o, --output CSV` | Write results to a CSV file. |
| `--threads N` | Concurrent probes (default: 10). |
| `--timeout N` | Per-request timeout in seconds (default: 10). |
`-ip` and `-f` are mutually exclusive; one is required.

## Output
Console lines are tagged by status:
[VULN] 172.17.3.142 iLO 6 fw 1.75 ved-srv-bck-ilo.esonpac.net ipmi:enabled -> CVE-2026-63457 [ OK ] 172.17.3.143 iLO 6 fw 1.81 ved-srv-dc1-ilo.esonpac.net ipmi:enabled [DEAD] 172.17.3.160



### Status values
| Status | Meaning |
|---|---|
| `vulnerable` | Firmware falls inside at least one known CVE range. |
| `ok` | Probed successfully, no known CVE range matches. |
| `no-version` | Endpoints answered but no firmware version could be extracted — worth a manual look. |
| `unreachable` | Both endpoints failed. |
| `error` | Unexpected failure during probe. |

### CSV columns
| Column | Content |
|---|---|
| `ip` | Target as given. |
| `status` | One of the statuses above. |
| `manager` | Manager type from the Redfish root (e.g. `iLO 6`). |
| `firmware` | iLO firmware version (Redfish OEM block, XML `FWRI` as fallback). |
| `fqdn` | iLO FQDN as configured by the admin. |
| `product` | Server model (e.g. `ProLiant DL20 Gen11`). |
| `serial` | **Server** serial number — pivot for warranty lookup, asset management, physical identification. |
| `ilo_serial` | **iLO** serial — corresponds to the factory default hostname pattern. |
| `ipmi_lan` | IPMI over LAN state from the XML `IPM` flag (`enabled` / `disabled`). |
| `cves` | Matching CVE IDs, `;`-separated, or `n/a` if no version was obtained. |
Rows are written in target-file order, so repeated sweeps over the same list
diff cleanly against each other.
## CVE table
The check logic is a flat, readable table at the top of the script:
| CVE | Manager | Affected range | Impact |
|---|---|---|---|
| CVE-2023-50272 | iLO 6 | 1.05 ≤ fw < 1.55 | Remote authentication bypass |
| CVE-2023-50272 | iLO 5 | 2.63 ≤ fw < 3.00 | Remote authentication bypass |
| CVE-2026-63457 | iLO 6 | fw < 1.78 | Unauthenticated DoS (unresponsive BMC) |
| CVE-2017-12542 | iLO 4 | fw < 2.53 | Auth bypass / RCE via Connection header overflow |
Version comparison uses integer tuples (`(1, 75) < (1, 78)`), not floats, so
`1.10` vs `1.9` ordering is handled correctly. Ranges with a lower bound are
respected: firmware below the affected set is not flagged.
To cover a new HPE security bulletin, add one tuple to `CVE_DB` and every
sweep re-classifies automatically.

## Operational notes
- **TLS verification is disabled** — iLOs ship self-signed factory certificates.
  Remember this cuts both ways in hostile network positions.
- **Logging footprint:** iLO records web access events in its audit log. A
  fleet sweep of N hosts leaves 2N log entries. The User-Agent is honest
  (`ilo-probe/1.0`) — change it in `fetch()` if your rules of engagement
  call for a lower-visibility profile.
- **Only two requests per host** — one `GET /redfish/v1/`, one
  `GET /xmldata?item=all`. Suitable for large unannounced recon phases within
  an authorized engagement scope.
- This tool only reads unauthenticated endpoints. It does not attempt logins,
  exploit anything, or change state on the target.

## Limitations / roadmap
- IPv6 targets work but are untested against large fleets.
- No RMCP/IPMI (UDP 623) probe yet — the `ipmi_lan` column reflects the
  XML-declared state, not a live check.
- `CVE_DB` is maintained by hand; there is no live-feed integration.

## Legal
For use only on systems you are explicitly authorized to test. The tool
performs read-only unauthenticated requests, but pointing it at infrastructure
you don't have permission to assess is still unauthorized access in most
jurisdictions.
