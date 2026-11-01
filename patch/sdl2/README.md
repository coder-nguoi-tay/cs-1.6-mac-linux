# SDL2 patch — fix "black screen / frozen UI" hang (macOS)
SDL 2.30.12 `src/video/cocoa/SDL_cocoaopengl.m`:
- Xát quá trình wait trong `Cocoa_GL_SwapWindow` (2 chỗ): `SDL_CondWait` → `SDL_CondWaitTimeout(..., 100)`.
- Nguyên nhân gốc: giữ framework pause (occlusion/background) làm CVDisplayLink ngừng phát sinh event; `Cocoa_GL_SwapWindow` nhấn pause chờ vô hạn → LuaScreen black khi ESC menu mở phím restart.
- Build: cmake Release arm64 + Link SDL2 shared only, install /tmp/sdlreal → libSDL2-2.0.0.dylib khỏi bị hang.
