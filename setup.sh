#!/usr/bin/env bash
# =============================================================================
#  jerome-config installer
#  Symlinks configs into place and (optionally) installs Brewfile packages.
#  Safe to re-run: existing real files are backed up, stale symlinks replaced.
# =============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "[${GREEN}INFO${NC}] $*"; }
warn()  { echo -e "[${YELLOW}WARN${NC}] $*"; }
header(){ echo -e "\n${BLUE}===== $* =====${NC}"; }

# link <source-in-repo> <target-in-home>
link() {
  local src="$1" dest="$2"

  # Already correctly linked -> nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    info "ok      $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  # Back up a real file/dir; just remove a stale symlink.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ]; then
      warn "relink  $dest (was -> $(readlink "$dest"))"
      rm "$dest"
    else
      mkdir -p "$BACKUP_DIR"
      warn "backup  $dest -> $BACKUP_DIR/"
      mv "$dest" "$BACKUP_DIR/"
    fi
  fi

  ln -s "$src" "$dest"
  info "link    $dest -> $src"
}

header "Symlinking configs"
link "$DOTFILES/zsh/.zshrc"              "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile"           "$HOME/.zprofile"
link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/git/.gitignore_global"   "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                    "$HOME/.config/nvim"
link "$DOTFILES/starship/starship.toml"  "$HOME/.config/starship.toml"
link "$DOTFILES/tmux/tmux.conf"          "$HOME/.config/tmux/tmux.conf"

header "Homebrew packages"
if command -v brew >/dev/null 2>&1; then
  read -rp "Run 'brew bundle' to install Brewfile packages? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    brew bundle --file="$DOTFILES/Brewfile"
  else
    info "Skipped. Run later: brew bundle --file=$DOTFILES/Brewfile"
  fi
else
  warn "brew not found — install Homebrew first: https://brew.sh"
fi

header "Done"
info "Backups (if any) are in $BACKUP_DIR"
info "Restart your shell or run: source ~/.zshrc"
