#!/bin/zsh
# Build cs16-client (client + ReGameDLL + YaPB + MainUI menu)
# Áp patch menu 5 nút classic trước khi build.
# @author Codernguoitay @since 2026-10-31
set -e
cd "$(dirname "$0")"/..
mkdir -p src && cd src
[ -d cs16-client ] || git clone --recursive --depth 1 https://github.com/FWGS/cs16-client.git
cd cs16-client
# apply classic menu patch
git apply --check ../../patch/mainui/main_classic_menu.patch 2>/dev/null \
  && git apply ../../patch/mainui/main_classic_menu.patch \
  || cp ../../patch/mainui/Main.cpp 3rdparty/mainui_cpp/menus/Main.cpp \
  &&  cp ../../patch/mainui/Credits.cpp 3rdparty/mainui_cpp/menus/Credits.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-I/tmp/sdlreal/include" -DCMAKE_CXX_FLAGS="-I/tmp/sdlreal/include" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/tmp/sdlreal/lib"
cmake --build build -j8
cd ../..
mkdir -p runtime/cstrike/cl_dlls runtime/cstrike/dlls
cp src/cs16-client/build/3rdparty/mainui_cpp/menu_arm64.dylib runtime/
cp src/cs16-client/build/cl_dlls/client_arm64.dylib runtime/cstrike/cl_dlls/ 2>/dev/null \
   || cp src/cs16-client/build/client_arm64.dylib runtime/cstrike/cl_dlls/ 2>/dev/null || true
cp src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/cs_arm64.dylib runtime/cstrike/dlls/
cp src/cs16-client/build/3rdparty/yapb/yapb_arm64.dylib runtime/cstrike/dlls/
echo "menu/client servers -> runtime/"
