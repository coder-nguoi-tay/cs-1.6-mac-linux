#!/bin/bash
# Build CS 1.6 native cho Linux x86_64 (chay trong Docker/any Linux amd64)
# Reuses sources on mounted repo (src/xash3d-fwgs, src/cs16-client) so patches persist.
# Output: runtime-linux/
# @author codernguoitay @since 2026-10-31
set -e
SRC="$(cd "$(dirname "$0")"/.. && pwd)"
[ -d "$SRC/src/xash3d-fwgs" ] || { mkdir -p "$SRC/src" && cd "$SRC/src" && git clone --recursive --depth 1 https://github.com/FWGS/xash3d-fwgs.git && cd ..; }
[ -d "$SRC/src/cs16-client" ] || { cd "$SRC/src" && git clone --recursive --depth 1 https://github.com/FWGS/cs16-client.git && cd ..; }

# SDL2 dev (mắc nhầm sẽ tự cài)
if ! command -v sdl2-config >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++ libsdl2-dev build-essential cmake python3 pkg-config libxxf86vm-dev libx11-dev x11proto-dev libfreetype-dev libfontconfig-dev libgl1-mesa-dev >/dev/null 2>&1
fi
export SDL2_CONFIG=$(which sdl2-config)

# ---------- 1. Engine ----------
cd "$SRC/src/xash3d-fwgs"
./waf configure --out=build-linux -8 --disable-mbedtls || exit 1
./waf build -j1 || exit 1
mkdir -p "$SRC/runtime-linux/cstrike/cl_dlls" "$SRC/runtime-linux/cstrike/dlls"
cp build-linux/xash3d build-linux/libxash.so "$SRC/runtime-linux/" 2>/dev/null || cp build-linux/*.so "$SRC/runtime-linux/" 2>/dev/null || true
cp build-linux/filesystem/filesystem_stdio.so "$SRC/runtime-linux/" 2>/dev/null || true
cp build-linux/ref/*/libref_*.so "$SRC/runtime-linux/" 2>/dev/null || true
cp build-linux/3rdparty/mainui_cpp/menu_*.so "$SRC/runtime-linux/" 2>/dev/null || true
find build-linux -name "*.so" -maxdepth 1 -exec cp {} "$SRC/runtime-linux/" \; 2>/dev/null || true
cp /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0* "$SRC/runtime-linux/" 2>/dev/null || true

# ---------- 2. cs16-client ----------
cd "$SRC/src/cs16-client"
cp "$SRC/patch/mainui/Main.cpp" 3rdparty/mainui_cpp/menus/Main.cpp
cp "$SRC/patch/mainui/Credits.cpp" 3rdparty/mainui_cpp/menus/Credits.cpp
cp "$SRC/patch/mainui/CreateGame.cpp" 3rdparty/mainui_cpp/menus/CreateGame.cpp
cp "$SRC/patch/cs16/beam_client_stub.cpp" cl_dll/
# GCC strict fixes (ných idempotent)
grep -q "enum netsrc_s { NS_CLIENT" engine/APIProxy.h 2>/dev/null || sed -i 's|void (\*pfnNET_SendPacket)(enum netsrc_s sock|"enum netsrc_s { NS_CLIENT, NS_SERVER };\\n\\tvoid (*pfnNET_SendPacket)(enum netsrc_s sock|' engine/APIProxy.h 2>/dev/null || true
cmake -B build-linux -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build build-linux -j2
cp build-linux/3rdparty/mainui_cpp/menu_*.so "$SRC/runtime-linux/" 2>/dev/null
cp build-linux/cl_dll/client*.so "$SRC/runtime-linux/cstrike/cl_dlls/" 2>/dev/null || cp "$SRC/src/cs16-client/build-linux/cl_dll/"client*.so "$SRC/runtime-linux/cstrike/cl_dlls/" 2>/dev/null
find build-linux -name "client*.so" -exec cp {} "$SRC/runtime-linux/cstrike/cl_dlls/" \; 2>/dev/null || true
find build-linux -path "*ReGameDLL*" -name "cs*.so" -exec cp {} "$SRC/runtime-linux/cstrike/dlls/cs.so" \; 2>/dev/null || true
find build-linux -name "yapb*.so" -exec cp {} "$SRC/runtime-linux/cstrike/dlls/yapb.so" \; 2>/dev/null || true
cp "$SRC/patch/mainui/liblist.gam" "$SRC/runtime-linux/cstrike/liblist.gam"
cp "$SRC/patch/mainui/userconfig.cfg" "$SRC/runtime-linux/cstrike/"
cp "$SRC/scripts/run-cs16-linux.sh" "$SRC/runtime-linux/" && chmod +x "$SRC/runtime-linux/"*.sh
echo "LINUX BUILD OK -> runtime-linux/"
