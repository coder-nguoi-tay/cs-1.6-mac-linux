#!/bin/bash
# Launcher CS 1.6 native Linux
# @author Codernguoitay @since 2026-10-31
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
export LD_LIBRARY_PATH="$DIR:$DIR/cstrike:$LD_LIBRARY_PATH"
pkill -9 -f xash3d 2>/dev/null
exec ./xash3d -game cstrike -log -fullscreen \
  "+maxplayers 14" "+yb_quota 9" "+mp_roundtime 9" "+mp_timelimit 30" "$@"
