#!/bin/zsh
# Build SDL2 2.30.12 native (NOT homebrew sdl2-compat, which needs SDL3 and hangs Xash)
# @author Codernguoitay @since 2026-10-31
set -e
cd /tmp
[ -d SDL2 ] || git clone --depth 1 -b release-2.30.12 https://github.com/libsdl-org/SDL.git SDL2
cd SDL2
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/tmp/sdlreal \
      -DSDL_FRAMEWORK=ON -DCMAKE_FRAMEWORK_PATH=/tmp/SDL2.framework
cmake --build build -j8
cmake --install build
# also produce root sysroot for engine build linkage
cmake -B build -DCMAKE_INSTALL_PREFIX=/tmp/sdlroot -DSDL_FRAMEWORK=OFF >/dev/null
cmake --install build >/dev/null
rm -rf /tmp/SDL2.framework; cp -R build/SDL2.framework /tmp/SDL2.framework 2>/dev/null || true
echo done
