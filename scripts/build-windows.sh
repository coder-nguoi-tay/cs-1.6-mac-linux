#!/bin/zsh
# Cross-build CS 1.6 native cho Windows x86-64 tu Mac (mingw-w64).
# Yeu cau: brew install mingw-w64
# Output: runtime-windows/
# @author Codernguoitay @since 2026-10-31
set -e
SRC="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/tmp/mingwbin:/opt/homebrew/opt/mingw-w64/bin:$PATH"
export PKG_CONFIG_PATH=/tmp/sdl_win/lib/pkgconfig
export CC=/opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export MINGW_PREFIX=/opt/homebrew/opt/mingw-w64/lib/mingw64

# ---------- 1. SDL2 for Windows (cross) ----------
mkdir -p src && cd src
if [ ! -f /tmp/sdl_win/lib/libSDL2.a -a ! -f /tmp/sdl_win/lib/libSDL2.dll.a ]; then
  [ -d SDL2 ] || git clone --depth 1 -b release-2.30.12 https://github.com/libsdl-org/SDL.git SDL2
  cd SDL2
  cmake -B build -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=AMD64 \
    -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_INSTALL_PREFIX=/tmp/sdl_win \
    -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TEST_LIBRARY=OFF \
    -DSDL_AUDIO=ON -DSDL_RENDER=OFF \
    -DSDL_X11=OFF -DSDL_WAYLAND=OFF \
    -DSDL_OPENGLES=OFF -DSDL_OGG=OFF -DSDL_VULKAN=OFF >/dev/null
  cmake --build build -j8 >/dev/null
  cmake --install build >/dev/null
  cd ..
fi

# ---------- 2. Engine Xash3D-FWGS (win64 cross) ----------
[ -d xash3d-fwgs ] || git clone --recursive --depth 1 https://github.com/FWGS/xash3d-fwgs.git
cd xash3d-fwgs
./waf clean 2>/dev/null || true
./waf configure -8 -T release --prefix="$PWD/out" >/dev/null
./waf build -j8 >/dev/null
./waf install >/dev/null 2>&1 || true

# ---------- 3. cs16-client (win64 cross) ----------
cd ..
[ -d cs16-client ] || git clone --recursive --depth 1 https://github.com/FWGS/cs16-client.git
cd cs16-client
cp ../cs-1.6-mac-linux/patch/mainui/Main.cpp 3rdparty/mainui_cpp/menus/Main.cpp 2>/dev/null || \
  cp "$SRC/patch/mainui/Main.cpp" 3rdparty/mainui_cpp/menus/Main.cpp
cp "$SRC/patch/mainui/Credits.cpp" 3rdparty/mainui_cpp/menus/Credits.cpp
cat > toolchain.cmake <<'EOF'
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(PKG_CONFIG_EXECUTABLE /nonexistent) # force SDL2 path
set(SDL2_INCLUDE_DIR /tmp/sdl_win/include/SDL2)
set(SDL2_LIBRARY /tmp/sdl_win/lib/libSDL2.dll.a)
EOF
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
  -DSDL2_PATH=/tmp/sdl_win >/dev/null
cmake --build build -j8 >/dev/null

# ---------- 4. Assemble runtime-windows ----------
cd "$SRC"
mkdir -p runtime-windows/cstrike/cl_dlls runtime-windows/cstrike/dlls
ENGBIN=src-xash.out
cp src/xash3d-fwgs/out/xash.exe src/xash3d-fwgs/out/xash.dll runtime-windows/ 2>/dev/null \
  || find src/xash3d-fwgs -name "xash*" \( -name "*.exe" -o -name "*.dll" \) -exec cp {} runtime-windows/ \;
cp /tmp/sdl_win/bin/SDL2.dll runtime-windows/ 2>/dev/null \
  || cp /tmp/sdl_win/lib/SDL2.dll runtime-windows/ 2>/dev/null || true
cp src/cs16-client/build/3rdparty/mainui_cpp/menu*.dll runtime-windows/ 2>/dev/null || true
cp src/cs16-client/build/cl_dlls/client*.dll runtime-windows/cstrike/cl_dlls/ 2>/dev/null || true
cp src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/cs.dll runtime-windows/cstrike/dlls/cs.dll 2>/dev/null \
  || cp src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/*.dll runtime-windows/cstrike/dlls/cs.dll
cp src/cs16-client/build/3rdparty/yapb/*.dll runtime-windows/cstrike/dlls/yapb.dll 2>/dev/null || true
cp patch/mainui/liblist.gam runtime-windows/cstrike/
cp patch/mainui/userconfig.cfg runtime-windows/cstrike/
echo "WINDOWS BUILD OK -> runtime-windows/"; ls -la runtime-windows
