#!/bin/zsh
# Build Xash3D-FWGS engine (native arm64)
# @author Codernguoitay @since 2026-10-31
set -e
mkdir -p src && cd src
[ -d xash3d-fwgs ] || git clone --recursive --depth 1 https://github.com/FWGS/xash3d-fwgs.git
cd xash3d-fwgs
export SDL2_CONFIG="/tmp/sdlreal/bin/sdl2-config"
export PKG_CONFIG_PATH="/tmp/sdlreal/lib/pkgconfig:$PKG_CONFIG_PATH"
./waf configure --prefix="$PWD/build/bin" --enable-gles1 --enable-gles2 >/dev/null 2>&1 || ./waf configure
./waf build -j8
./waf install
mkdir -p ../../runtime/cstrike
cp build/bin/xash3d build/lib/public/libxash.dylib build/lib/public/libref_gl.dylib \
   build/lib/public/filesystem_stdio.dylib ../../runtime/ 2>/dev/null \
   || cp build/bin/*.{dylib,x} ../../runtime/ 2>/dev/null || true
cp /tmp/sdlreal/lib/libSDL2-2.0.0.dylib ../../runtime/ 2>/dev/null || true
echo "engine -> runtime/"
