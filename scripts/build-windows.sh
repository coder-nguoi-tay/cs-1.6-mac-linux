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
export CXX=/opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-g++
# Apple ar/ranlib cannot index PE archives (empty TOC -> mingw ld undefined refs); use mingw binutils for archives
export AR=/opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-ar
export RANLIB=/opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-ranlib
export MINGW_PREFIX=/opt/homebrew/opt/mingw-w64/lib/mingw64

mkdir -p /tmp/mingwbin
cat > /tmp/mingwbin/windres <<'WEOF'
#!/bin/sh
# Real mingw windres (llvm-windres spec outputs aarch64 COFF on mac host, incompatible with mingw ld)
exec /opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-windres "$@"
WEOF
chmod +x /tmp/mingwbin/windres

# ---------- 1. SDL2 for Windows (cross) ----------
mkdir -p src && cd src
if [ ! -f /tmp/sdl_win/lib/libSDL2.dll.a ] && [ ! -f /tmp/sdl_win/lib/libSDL2.a ]; then
  [ -d SDL2 ] || git clone --depth 1 -b release-2.30.12 https://github.com/libsdl-org/SDL.git SDL2
  cd SDL2
  cat > toolchain-win64.cmake <<'EOF'
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_C_COMPILER /opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER /opt/homebrew/Cellar/mingw-w64/14.0.0_3/toolchain-x86_64/bin/x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER /tmp/mingwbin/windres)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF
  rm -rf build
  cmake -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-win64.cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/tmp/sdl_win \
    -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TEST_LIBRARY=OFF \
    -DSDL_AUDIO=ON -DSDL_RENDER=OFF \
    -DSDL_X11=OFF -DSDL_WAYLAND=OFF \
    -DSDL_OPENGLES=OFF -DSDL_OGG=OFF -DSDL_VULKAN=OFF >/dev/null
  cp patch/cs16/conout_stub.cpp src/cs16-client/3rdparty/ReGameDLL_CS/regamedll/conout_stub.cpp
# ReGameDLL CMake treats any non-MSVC WIN32 build as posix -> use platform_win32.cpp for mingw
python3 - <<'PYRG'
p="3rdparty/ReGameDLL_CS/regamedll/CMakeLists.txt"
s=open(p).read()
old='''else()
\tset(GAMEDLL_SRCS ${GAMEDLL_SRCS}
\t\t"public/tier0/platform_posix.cpp")
endif()'''
new='''elseif(WIN32)
\tset(GAMEDLL_SRCS ${GAMEDLL_SRCS}
\t\t"public/tier0/platform_win32.cpp")
else()
\tset(GAMEDLL_SRCS ${GAMEDLL_SRCS}
\t\t"public/tier0/platform_posix.cpp")
endif()'''
if old in s and "elseif(WIN32)" not in s:
    s=s.replace(old,new,1); open(p,"w").write(s)
PYRG
# yapb 64-bit: skip i386 PE ldscript (only valid for 32-bit); relax -Werror for newer GCC analyzers
python3 - <<'PYY'
p="3rdparty/yapb/cmake/YapbFlags.cmake"
s=open(p).read()
s=s.replace('if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")\n      list(APPEND _ldflags -Xlinker --script -Xlinker ${PROJECT_SOURCE_DIR}/ext/ldscripts/i386pe.lds)','if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_SIZEOF_VOID_P EQUAL 4)\n      list(APPEND _ldflags -Xlinker --script -Xlinker ${PROJECT_SOURCE_DIR}/ext/ldscripts/i386pe.lds)',1)
s=s.replace("_strict_ldflags -Werror","_strict_ldflags -Wno-error")
s=s.replace("-Werror)","-Wno-error)")
open(p,"w").write(s)
PYY
cmake --build build -j8 >/dev/null
  cmake --install build >/dev/null
  cd ..
fi

# engine waf: ALWAYS use bundled miniz (system-zlib detection may pick host libz on cross builds)
python3 - <<'PYMZ'
p="xash3d-fwgs/wscript"
s=open(p).read()
old="Subproject('3rdparty/miniz', lambda x: not x.env.HAVE_SYSTEM_ZLIB),"
new="Subproject('3rdparty/miniz', lambda x: True), # always bundled miniz (cross-build safe)"
if old in s and "Cross-build safe" not in s:
    s=s.replace(old,new,1); open(p,"w").write(s)
PYMZ
# ---------- 2. Engine Xash3D-FWGS (win64 cross) ----------
[ -d xash3d-fwgs ] || git clone --recursive --depth 1 https://github.com/FWGS/xash3d-fwgs.git
cd xash3d-fwgs
# (do not clean: reuse existing build; run 'rm -rf build' manually for a fully fresh build)
mkdir -p /tmp/sdl_win/x86_64-w64-mingw32 && ln -sfn /tmp/sdl_win /tmp/sdl_win/x86_64-w64-mingw32
./waf configure -8 -T release --prefix="$PWD/out" > /tmp/wafcfg.log 2>&1
./waf build -j8 >/dev/null
./waf install >/dev/null 2>&1 || true

# ---------- 3. cs16-client (win64 cross) ----------
cd ..
[ -d cs16-client ] || git clone --recursive --depth 1 https://github.com/FWGS/cs16-client.git
cd cs16-client
cp ../cs-1.6-mac-linux/patch/mainui/Main.cpp 3rdparty/mainui_cpp/menus/Main.cpp 2>/dev/null || \
  cp "$SRC/patch/mainui/Main.cpp" 3rdparty/mainui_cpp/menus/Main.cpp
cp "$SRC/patch/mainui/Credits.cpp" 3rdparty/mainui_cpp/menus/Credits.cpp
cp "$SRC/patch/mainui/CreateGame.cpp" 3rdparty/mainui_cpp/menus/CreateGame.cpp
cp "$SRC/patch/cs16/beam_client_stub.cpp" cl_dll/
# GCC strict-mode: void* -> function pointer conversion in interface.cpp needs reinterpret_cast
sed -i '' 's|return static_cast<CreateInterfaceFn>( Sys_GetProcAddress( pModuleName, CREATEINTERFACE_PROCNAME ) );|return reinterpret_cast<CreateInterfaceFn>( Sys_GetProcAddress( pModuleName, CREATEINTERFACE_PROCNAME ) );|' common/interface.cpp
# GCC strict-mode: vendored APIProxy.h references enum netsrc_s without definition -> inject goldsrc named enum
python3 - <<'PYEOF'
p="engine/APIProxy.h"
s=open(p).read()
if "enum netsrc_s" in s and "{" not in s.split("enum netsrc_s")[1][:40]:
    marker="void (*pfnNET_SendPacket)(enum netsrc_s sock"
    s=s.replace(marker, "enum netsrc_s { NS_CLIENT, NS_SERVER };\n\n\t"+marker, 1)
    open(p,"w").write(s)
PYEOF
# ReGameDLL: -ldl only on POSIX
python3 -c "
p='3rdparty/ReGameDLL_CS/regamedll/CMakeLists.txt'
s=open(p).read()
if 'NOT MSVC AND NOT WIN32' not in s:
    s=s.replace('if(NOT MSVC)'+chr(10)+'\tset(LINK_LIBS dl)','if(NOT MSVC AND NOT WIN32)'+chr(10)+'\tset(LINK_LIBS dl)',1)
    open(p,'w').write(s)
"
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
  -DCMAKE_CXX_FLAGS="-fpermissive -w" \
  -DYAPB_64BIT=ON -DYAPB_WITH_AMXX=OFF -DYAPB_LTO=OFF \
  -DSDL2_PATH=/tmp/sdl_win >/dev/null
# mingw signal.h lacks SIGTRAP -> patch ReGameDLL DebuggerBreak
python3 - <<'PYEOF'
p="3rdparty/ReGameDLL_CS/regamedll/public/tier0/platform.h"
s=open(p).read()
old="""	#include <signal.h>

	#define DebuggerBreak() raise(SIGTRAP)"""
new="""	#include <signal.h>

	#if defined(__MINGW32__)
		#define DebuggerBreak() __builtin_trap()
	#else
		#define DebuggerBreak() raise(SIGTRAP)
	#endif"""
if old in s and "__MINGW32__" not in s:
    s=s.replace(old,new); open(p,"w").write(s)
PYEOF
cmake --build build -j8 >/dev/null

# ---------- 4. Assemble runtime-windows ----------
cd "$SRC"
mkdir -p runtime-windows/cstrike/cl_dlls runtime-windows/cstrike/dlls
ENGBIN=src-xash.out
cp src/xash3d-fwgs/out/xash.exe src/xash3d-fwgs/out/xash.dll runtime-windows/ 2>/dev/null \
  || find src/xash3d-fwgs -name "xash*" \( -name "*.exe" -o -name "*.dll" \) -exec cp {} runtime-windows/ \;
cp src/xash3d-fwgs/build/filesystem/filesystem_stdio.dll runtime-windows/ 2>/dev/null || true
cp src/xash3d-fwgs/build/ref/gl/ref_gl.dll runtime-windows/ 2>/dev/null || true
cp /tmp/sdl_win/bin/SDL2.dll runtime-windows/ 2>/dev/null \
  || cp /tmp/sdl_win/lib/SDL2.dll runtime-windows/ 2>/dev/null || true
cp src/cs16-client/build/3rdparty/mainui_cpp/menu*.dll runtime-windows/ 2>/dev/null || true
cp src/cs16-client/build/cl_dll/client_amd64.dll runtime-windows/cstrike/cl_dlls/client.dll 2>/dev/null || cp src/cs16-client/build/cl_dlls/client*.dll runtime-windows/cstrike/cl_dlls/ 2>/dev/null || true
cp src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/cs.dll runtime-windows/cstrike/dlls/cs.dll 2>/dev/null \
  || cp src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/*.dll runtime-windows/cstrike/dlls/cs.dll
cp src/cs16-client/build/3rdparty/yapb/*.dll runtime-windows/cstrike/dlls/yapb.dll 2>/dev/null || true
cp patch/mainui/liblist.gam runtime-windows/cstrike/
cp patch/mainui/userconfig.cfg runtime-windows/cstrike/
echo "WINDOWS BUILD OK -> runtime-windows/"; ls -la runtime-windows
