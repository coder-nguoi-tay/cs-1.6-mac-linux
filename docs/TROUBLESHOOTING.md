# Troubleshooting

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Treo lúc khởi động / đen màn hình | dùng SDL2-compat từ brew | build SDL2 thật: `scripts/build-sdl2.sh` |
| Log đỏ "no servers to download" khi online | fastdl server chết | `cl_allowdownload 0` (đã có trong userconfig.cfg) |
| Menu không có New Game | gamedll lỗi / patch chưa áp | kiểm `cstrike/liblist.gam` + chép lại `menu_arm64.dylib` |
| Vào game thiếu tiếng súng | server dùng sound custom không tải được là chủ đích | chấp nhận, hoặc tự bỏ sound vào `cstrike/sound` |
| Engine không thấy server.dll | `cs_arm64.dylib` không đúng vị trí | `cstrike/dlls/cs_arm64.dylib` |
| Không tìm thấy phòng LAN | firewall chặn UDP | Allow trong System Settings (lần đầu) |
| crash crash dấu vết lạ? | nhiều instance cũ | `pkill -9 -f xash3d` rồi chạy lại |
