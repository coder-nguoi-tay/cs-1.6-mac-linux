#!/bin/zsh
# Copy gamedata từ bản CS 1.6 gốc (Wine installer/PC copy) vào runtime/,
# rồi ghi đè patch runtime files.
# Usage: ./install-gamedata.sh "/path/to/Counter Strike Cataclysm"
# @author Codernguoitay @since 2026-10-31
set -e
SRC="${1:?Usage: install-gamedata.sh /path/to/Counter Strike Cataclysm}"
cd "$(dirname "$0")/.."
RUN="$PWD/runtime"
mkdir -p "$RUN/cstrike"
rsync -a "$SRC/valve"  "$RUN/" 2>/dev/null || echo "(khong co valve/ bo qua)"
rsync -a "$SRC/cstrike" "$RUN/"
# patch: gamedll -> dlls\cs
if [ -f "$RUN/cstrike/liblist.gam" ]; then
  sed -i '' 's/^gamedll.*/gamedll "dlls\\cs"/' "$RUN/cstrike/liblist.gam"
fi
# patch: userconfig (HUD vang, khong download fastdl chet, khong auto map)
cp patch/mainui/userconfig.cfg "$RUN/cstrike/userconfig.cfg"
# chép dylibs đã build/tải sẵn vào gamedata
cp -R "$RUN"/libxash.dylib "$RUN"/libref_gl.dylib "$RUN"/filesystem_stdio.dylib \
      "$RUN"/libSDL2-2.0.0.dylib "$RUN"/xash3d "$RUN"/ 2>/dev/null || true
cp prebuilt/menu_arm64.dylib "$RUN/" 2>/dev/null || true
for f in prebuilt/cstrike/cl_dlls/*;  do cp "$f" "$RUN/cstrike/cl_dlls/" 2>/dev/null; done
for f in prebuilt/cstrike/dlls/*;     do cp "$f" "$RUN/cstrike/dlls/" 2>/dev/null; done
cp scripts/run-cs16.command "$RUN/" && chmod +x "$RUN/run-cs16.command"
echo "Xong! chay runtime/run-cs16.command"
