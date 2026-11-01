#!/bin/bash
# Build CS 1.6 native cho Linux x86_64 (chay trong Docker/any Linux)
# Output: ../runtime-linux/
# @author Codernguoitay @since 2026-10-31
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq git curl build-essential cmake python3 pkg-config \
  libsdl2-dev libxxf86vm-dev libx11-dev x11proto-dev libfreetype-dev libfontconfig-dev libgl1-mesa-dev >/dev/null 2>&1
SRC="$(cd "$(dirname "$0")"/.. && pwd)"
mkdir -p /src && cd /src
[ -d xash3d-fwgs ] || git clone --recursive --depth 1 https://github.com/FWGS/xash3d-fwgs.git
[ -d cs16-client ] || git clone --recursive --depth 1 https://github.com/FWGS/cs16-client.git
# SDL2
if [ ! -f /usr/lib/x86_64-linux-gnu/libSDL2.so ]; then
  apt-get install -y libsdl2-dev >/dev/null 2>&1 || sudo apt-get install -y libsdl2-dev
fi
export SDL2_CONFIG=$(which sdl2-config)
cd /src/xash3d-fwgs
./waf configure build -j8 || { ./waf configure; ./waf build -j8; }
mkdir -p "$SRC/runtime-linux/cstrike/cl_dlls" "$SRC/runtime-linux/cstrike/dlls"
cp build/bin/xash3d build/bin/libxash.so "$SRC/runtime-linux/" 2>/dev/null || cp build/bin/* "$SRC/runtime-linux/"
cp build/lib/public/*.so "$SRC/runtime-linux/" 2>/dev/null || true
cp /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0* "$SRC/runtime-linux/" 2>/dev/null || true
# client
cd /src/cs16-client
cp "$SRC/patch/mainui/Main.cpp"   3rdparty/mainui_cpp/menus/Main.cpp
cp "$SRC/patch/mainui/Credits.cpp" 3rdparty/mainui_cpp/menus/Credits.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build build -j8
mkdir -p "$SRC/runtime-linux/cstrike/cl_dlls" "$SRC/runtime-linux/cstrike/dlls"
cp build/3rdparty/mainui_cpp/menu_*32.so "$SRC/runtime-linux/menu_i386.so" 2>/dev/null || cp build/3rdparty/mainui_cpp/menu_*.so "$SRC/runtime-linux/" 2>/dev/null
cp build/cl_dlls/client_*client.so "$SRC/runtime-linux/cstrike/cl_dlls/" 2>/dev/null || cp build/cl_dlls/*.so "$SRC/runtime-linux/cstrike/cl_dlls/"
cp build/3rdparty/ReGameDLL_CS/regamedll/cs_i386.so "$SRC/runtime-linux/cstrike/dlls/cs.so" 2>/dev/null || cp build/3rdparty/ReGameDLL_CS/regamedll/*.so "$SRC/runtime-linux/cstrike/dlls/cs.so"
cp build/3rdparty/yapb/*.so "$SRC/runtime-linux/cstrike/dlls/yapb.so"
cp "$SRC/patch/mainui/liblist.gam" "$SRC/runtime-linux/cstrike/liblist.gam"
cp "$SRC/patch/mainui/userconfig.cfg" "$SRC/runtime-linux/cstrike/"
cp "$SRC/scripts/run-cs16-linux.sh" "$SRC/runtime-linux/" && chmod +x "$SRC/runtime-linux/"*.sh
echo "LINUX BUILD OK -> runtime-linux/"
