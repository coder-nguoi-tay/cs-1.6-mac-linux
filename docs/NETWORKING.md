# Logic mạng LAN chung WiFi

Engine Xash3D-FWGS chạy đúng như logic GoldSrc PC trên mạng LAN/quán WiFi:

## Mức mặc định đã build sẵn
- **Server listen (host phòng)**: `New Game` tạo local server, UDP bind
  `*:27015` (cvar `ip_hostport`). Query/broadcast hoạt động — có thể ping
  qua A2S_INFO từ bất kỳ máy nào chung WiFi.
- **Client tìm phòng LAN**: `Find Servers → LAN` — client broadcast UDP tới
  cổng server discovery (27010 theo convention GoldSrc/Xash); các phòng cùng
  subnet sẽ hiện list. Nhấn `Connect` như PC.
- **`sv_lan 1`**: bật竞技 LAN thuần (không heartbeat, rate 9 999 vượt which,
  không authenticate) — tương đương logic "quán nét" LAN server của bản PC.
  Đặt vào `cstrike/server.cfg`.

## Nhật ký cần biết
- `Could not get TCP/IPv4 address, Invalid hostname` — chỉ связано with
  TCP helper (HLTV/voice), UDP LAN chơi bình thường.
- Voice capture (CoreAudio error) — chỉ warning mất *thu âm mic*, không hiện        				không game.

## Snapshot mạng đã kiểm
1. Host tạo map (bots auto fill `yb_quota`), UDP 27015 bind OK.
2. A2S_INFO từ máy khác (hoặc terminal python) trả về đúng map hiện .
3. `Find Servers → LAN` client hiện phòng, join → chơi OK.

## Firewall
macOS sẽ hỏi allow network lần đầu — chọn Allow. Không cần thêm inbound rule.
