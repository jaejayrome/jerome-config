#!/usr/bin/env bash
# =============================================================================
#  jerome-config installer
#  Symlinks configs into place with GNU Stow and (optionally) installs Brewfile.
#  Safe to re-run: --restow refreshes links; real files that would conflict are
#  backed up first so Stow won't abort.
# =============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup"

# Stow packages (each mirrors $HOME internally). Add new dirs here.
STOW_PACKAGES=(zsh git nvim starship tmux)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "[${GREEN}INFO${NC}] $*"; }
warn()  { echo -e "[${YELLOW}WARN${NC}] $*"; }
header(){ echo -e "\n${BLUE}===== $* =====${NC}"; }

header "GNU Stow"
if ! command -v stow >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    info "stow not found — installing via Homebrew"
    brew install stow
  else
    warn "stow not found and Homebrew unavailable. Install stow, then re-run."
    exit 1
  fi
fi

# Move any real (non-symlink) file/dir that Stow would collide with out of the
# way, so a first run on a fresh machine doesn't abort. Existing Stow symlinks
# are left alone — --restow handles those.
backup_conflicts() {
  # Ask Stow (simulation mode) what it would link, then back up real targets.
  local line target
  while IFS= read -r line; do
    case "$line" in
      "LINK: "*"=>"*)
        target="${line#LINK: }"; target="${target%% =>*}"
        target="$HOME/$target"
        if { [ -e "$target" ] || [ -L "$target" ]; } && [ ! -L "$target" ]; then
          mkdir -p "$BACKUP_DIR"
          warn "backup  $target -> $BACKUP_DIR/"
          mv "$target" "$BACKUP_DIR/"
        fi
        ;;
    esac
  done < <(stow -n -v --dir="$DOTFILES" --target="$HOME" "${STOW_PACKAGES[@]}" 2>&1 || true)
}

header "Symlinking configs with Stow"
backup_conflicts
stow -v --restow --dir="$DOTFILES" --target="$HOME" "${STOW_PACKAGES[@]}"

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
info "To remove all symlinks later: stow -D --dir=\"$DOTFILES\" --target=\"$HOME\" ${STOW_PACKAGES[*]}"
