# CS 1.6 — Native Mac (Apple Silicon / arm64)

Port chơi **Counter-Strike 1.6 chuẩn 100% logic PC** trên macOS bằng engine open-source
**Xash3D-FWGS** + **cs16-client** (client + ReGameDLL + bot YaPB + menu MainUI),
kèm **menu chính classic 5 nút**: `NEW GAME / FIND SERVERS / OPTIONS / CREDITS / QUIT GAME`.

📁 **Gamedata (maps, models, sounds...) KHÔNG nằm trong repo này** vì bản quyền Valve.
Bạn phải tự cung cấp từ bản CS 1.6合法 của mình (thư mục `cstrike/` + `valve/`)
— ví dụ từ bản installer "Counter Strike Cataclysm" (chạy bằng Wine 1 lần để lấy data,
hoặc copy từ máy PC/máy quán nét cũ).

---

## A. Tải bản build sẵn (không cần build)

Trong thư mục `prebuilt/` của repo có sẵn các library arm64:

```
prebuilt/
├── xash3d                    # launcher engine
├── libxash.dylib             # engine core
├── libref_gl.dylib           # OpenGL renderer
├── filesystem_stdio.dylib    # filesystem
├── libSDL2-2.0.0.dylib       # SDL2 2.30.12 native (không dùng sdl2-compat!)
├── menu_arm64.dylib          # MainUI — đã patch menu 5 nút classic
├── cstrike/cl_dlls/client_arm64.dylib   # client CS
└── cstrike/dlls/cs_arm64.dylib          # game DLL (ReGameDLL)
    cstrike/dlls/yapb_arm64.dylib        # bot YaPB
```

Ghép nhanh (khi đã có gamedata cstrike/valve):

```bash
git clone https://github.com/coder-nguoi-tay/cs-1.6-mac-linux.git
cd cs-1.6-mac-linux
./scripts/install-gamedata.sh /path/to/"Counter Strike Cataclysm"
./scripts/run-cs16.command
```

> `install-gamedata.sh` copy `valve/` và `cstrike/` từ bản gốc của bạn, rồi
> ghi đè bằng patch: `liblist.gam` trỏ gamedll về `dlls\cs` (engine tự thêm
> `_arm64.dylib`), `userconfig.cfg` chỉnh HUD/menu, và chép dylibs.

## B. Build từ đầu (README đầy đủ từng bước)

Yêu cầu: macOS (đã test Apple Silicon M-series), `git`, `cmake`, `clang`
(Xcode CLT), Python 3. Không cần `sudo`.

### 1. SDL2 thật (BẮT BUỘC build từ source)

`brew sdl2` là sdl2-compat (chạy trên SDL3) và sẽ **treo engine**. Build thật:

```bash
./scripts/build-sdl2.sh
# -> install tới /tmp/sdlreal + sysroot /tmp/sdlroot + framework /tmp/SDL2.framework
```

### 2. Build engine Xash3D-FWGS

```bash
./scripts/build-xash.sh
# clone xash3d-fwgs (master) -> waf configure/build -> runtime/xash3d + libxash.dylib...
```

### 3. Build cs16-client (client + ReGameDLL + YaPB + MainUI)

```bash
./scripts/build-client.sh
# clone cs16-client + khởi tạo 3rdparty submodule
# áp patch/menu_classic.patch vào 3rdparty/mainui_cpp/menus/{Main,Credits}.cpp
# cmake build -> runtime/menu_arm64.dylib + cstrike/cl_dlls/client_arm64.dylib
#              + cstrike/dlls/{cs,yapb}_arm64.dylib
```

### 4. Ghép gamedata & chạy

```bash
./scripts/install-gamedata.sh "/Users/.../Counter Strike Cataclysm"
./scripts/run-cs16.command     # mở thẳng MENU CHÍNH (không auto +map)
```

Menu chính có đủ: **New Game** (tạo phòng offline + bot), **Find Servers** (LAN/
Internet — chơi chung WiFi qua tab LAN), **Options**, **Credits**, **Quit Game**.

### 5. Kiểm tra

-.Keys: `~` mở console; button bar: Esc vào menu khi đang chơi.
-Server LAN: máy khác chung WiFi mở **Find Servers → LAN** sẽ thấy phòng (UDP
27015 / broadcast); host dùng `sv_lan 1` cho LAN thuần (xem `docs/NETWORKING.md`).

---

## C. Cấu trúc repo

```
patch/mainui/            # 2 file đã patch menu 5-nút classic (Main.cpp, Credits.cpp)
                         # + liblist.gam mẫu, userconfig.cfg mẫu
scripts/                 # build-sdl2.sh, build-xash.sh, build-client.sh,
                         # install-gamedata.sh, run-cs16.command
docs/                    # NETWORKING.md (logic LAN/WiFi), TROUBLESHOOTING.md
prebuilt/                # dylibs arm64 build 2026-10-31 (kéo về là dùng)
```

## D. Lỗi đã xử lý sẵn (trong patches + config)

| Vấn đề | Fix |
|---|---|
| Menu hiện nút lỗi thời (Training Room/Load/...) | patch MainUI: đúng 5 nút CS 1.6 classic |
| Menu chồng nút khitific | layout VidInit viết lại (stack 5 nút, anchor bottom) |
| Treo khi dùng sdl2-compat | build SDL2 2.30.12 native |
| Download fastdl chết khi online (log đỏ 120s) | `cl_allowdownload 0`, `cl_download_ingame 0` |
| gamedll sai path | `liblist.gam` gamedll = `dlls\cs` |

## E. Bản quyền

Engine/client: GPL (các upstream tương ứng). Gamedata Valve © Valve — **tự chuẩn bị**,
kho ứng dụng nội bộ. Chỉ dùng trong môi trường gia đình/máy cá nhân.
## Bots & Create Game (fixed)
- "New Game" giờ mở trực tiếp **Create Game** (map, maxplayers, password) + bots tự join qua YaPB (`gamedll "dlls\yapb"` trong liblist.gam).
- `server.cfg` có `yb_quota 9` — phòng mới tạo luôn có 9 bot.
- macOS: tắt App Nap cho máy chỉ định nếu input menu bị "chết" khi idle:
  `defaults write NSGlobalDomain NSAppSleepDisabled -bool YES`
- F1/F2 (autobuy/rebuy) hoạt động; mua đồ chỉ trong buy time đầu round (như CS thật).
