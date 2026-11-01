#!/bin/zsh
# ================= CS 1.6 — Mac mini (native arm64) =================
# Engine: Xash3D-FWGS (open-source GoldSrc) + cs16-client + YaPB bots
# Data:   cstrike/ (Counter Strike Cataclysm assets, copied from the exe tree)
# @author Codernguoitay @since 2026-10-31
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
pkill -9 -f xash3d 2>/dev/null
# Vào thẳng MENU CHÍNH (tạo phòng/Cài đặt bằng tay như quán nét).
# Ở menu: Multiplayer → New Game = tạo phòng; Options = cài đặt;
# Console (phím ~) = lệnh hưu; yb_quota cho bot tự fill phòng mới tạo.
exec ./xash3d -game cstrike -log -fullscreen \
  "+maxplayers 14" "+yb_quota 9" \
  "+mp_roundtime 9" "+mp_timelimit 30" "$@" 2>&1 | tee -a "$DIR/engine.log"
