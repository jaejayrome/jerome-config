#!/usr/bin/env bash
# Muxy 2 settings. Muxy keeps its own settings.toml/terminal.toml in
# ~/Library/Application Support/Muxy 2/ and rewrites them, so instead of
# symlinking those files we set only the values we care about.
#
# Change a setting: edit a line below, then run `bash muxy/settings.sh`.
# Muxy applies it immediately, no restart needed.
# See every key and its current value: muxy config list
# Terminal keys start with `terminal.`; everything else is settings.toml.
set -euo pipefail

muxy() {
  for app in "$HOME/Applications/Muxy.app" /Applications/Muxy.app; do
    [ -x "$app/Contents/MacOS/muxy" ] && { "$app/Contents/MacOS/muxy" "$@"; return; }
  done
  echo "Muxy not installed, skipping." >&2
  exit 0
}

# Nerd Font so Neovim, eza and starship icons render instead of boxes.
# Installed by the Brewfile (cask "font-jetbrains-mono-nerd-font").
muxy config set terminal.font_families '["JetBrainsMono Nerd Font"]'
muxy config set terminal.font_size 13

muxy config set appearance.dark_theme "TokyoNight Storm"
muxy config set appearance.light_theme "TokyoNight Storm"
