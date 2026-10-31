#!/bin/zsh
# Launcher: CS 1.6 native — khởi động thẳng MENU CHÍNH (không auto +map).
# @author Codernguoitay @since 2026-10-31
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
pkill -9 -f xash3d 2>/dev/null
export DYLD_LIBRARY_PATH="$DIR:$DIR/cstrike:$DIR/cstrike/dlls:$DYLD_LIBRARY_PATH"
exec ./xash3d -game cstrike -log -fullscreen \
  "+maxplayers 14" "+yb_quota 9" \
  "+mp_roundtime 9" "+mp_timelimit 30" "$@" 2>&1 | tee -a "$DIR/engine.log"
