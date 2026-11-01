#!/bin/zsh
# PLAY GAME 1 — cs_italy (ton double-click 1 lan)
DIR="$(cd "$(dirname "$0")" && pwd)"; cd "$DIR"
pkill -9 -f xash3d 2>/dev/null
sleep 1
defaults write NSGlobalDomain NSAppSleepDisabled -bool YES 2>/dev/null
exec ./xash3d -game cstrike -log -fullscreen "+maxplayers 14" "+map cs_italy" 2>&1 | tee -a "$DIR/engine.log"
