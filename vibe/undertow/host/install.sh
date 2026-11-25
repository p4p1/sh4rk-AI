#!/usr/bin/env bash
set -euo pipefail

NAME="com.web.platform"
DEST="$HOME/.local/share/webplatform"

SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -f "$SRCDIR/host" ] || { echo "host binary not found" >&2; exit 1; }
[ -f "$SRCDIR/start.sh" ] || { echo "start.sh not found" >&2; exit 1; }
[ -f "$SRCDIR/$NAME.json" ] || { echo "$NAME.json not found" >&2; exit 1; }

mkdir -p "$DEST/extension"
cp "$SRCDIR/host" "$DEST/.host.new" && mv -f "$DEST/.host.new" "$DEST/host"
chmod 755 "$DEST/host"
cp -R "$SRCDIR/extension/." "$DEST/extension/"
sed "s|__DIR__|$DEST|g" "$SRCDIR/start.sh" > "$DEST/.start.new" && mv -f "$DEST/.start.new" "$DEST/start.sh"
chmod 755 "$DEST/start.sh"
sed "s|__DIR__|$DEST|g" "$SRCDIR/$NAME.json" > "$DEST/.manifest.new" && mv -f "$DEST/.manifest.new" "$DEST/$NAME.json"

case "$(uname -s)" in
  Darwin)
    DIRS=(
      "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
      "$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
      "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
      "$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"
    ) ;;
  Linux)
    DIRS=(
      "$HOME/.config/google-chrome/NativeMessagingHosts"
      "$HOME/.config/chromium/NativeMessagingHosts"
      "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/.config/microsoft-edge/NativeMessagingHosts"
      "$HOME/.mozilla/native-messaging-hosts"
    ) ;;
  *)
    echo "unsupported os: $(uname -s)" >&2
    exit 1 ;;
esac

for d in "${DIRS[@]}"; do
  mkdir -p "$d"
  cp "$DEST/$NAME.json" "$d/$NAME.json"
done

echo "host installed to $DEST"
echo "load the unpacked extension from $DEST/extension"
