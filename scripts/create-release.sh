#!/bin/zsh
# Tao GitHub Release v1.0 + upload builds (mac / linux / windows)
# @author Codernguoitay @since 2026-10-31
set -e
cd "$(dirname "$0")/.."
TAG="v1.0"
TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill | grep ^password= | cut -d= -f2)
[ -n "$TOKEN" ] || { echo "Khong co token github"; exit 1; }

# dong goi
rm -rf /tmp/cs-release && mkdir -p /tmp/cs-release
cp -R runtime /tmp/cs-release/cs16-mac-runtime 2>/dev/null || true
cp -R runtime-linux /tmp/cs-release/cs16-linux-runtime 2>/dev/null || true
cp -R runtime-windows /tmp/cs-release/cs16-windows-runtime 2>/dev/null || true
cp -R prebuilt /tmp/cs-release/cs16-mac-prebuilt
cd /tmp/cs-release
for d in cs16-*; do zip -qr "$d.zip" "$d"; done
cd - >/dev/null

API=https://api.github.com/repos/coder-nguoi-tay/cs-1.6-mac-linux
AUTH="Authorization: token $TOKEN"
REL=$(curl -s -H "$AUTH" "$API/releases")
RELID=$(echo "$REL" | python3 -c "import json,sys;d=json.load(sys.stdin);print([r['id'] for r in d if r['tag_name']=='$TAG'][0]) if d and any(r['tag_name']=='$TAG' for r in d) else ''")
if [ -z "$RELID" ]; then
  RELID=$(curl -s -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"tag_name\":\"$TAG\",\"name\":\"CS 1.6 Native v1.0\",\"body\":\"Ban build san: macOS arm64 / Linux x86_64 / Windows x86. Ban TU gamedata (cstrike+valve) tu ban CS 1.6 cua ban ROI copy tat ca file trong zip nay vao, roi chay run script.\",\"draft\":false}" \
    "$API/releases" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")
fi
for f in /tmp/cs-release/cs16-*.zip; do
  curl -s -H "$AUTH" -H "Content-Type: application/zip" --data-binary @"$f" \
    "$API/releases/$RELID/assets?name=$(basename $f)" | grep -o '"browser_download_url": "[^"]*"' | head -1
done
echo "RELEASE DONE"
