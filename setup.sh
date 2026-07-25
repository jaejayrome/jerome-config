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
STOW_PACKAGES=(zsh git nvim starship tmux vscode)

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

# Muxy stores settings.json in Application Support and rewrites the whole file on
# quit, so it can't be a Stow symlink. Copy our tracked version into place instead.
# Muxy must be quit first, or it will overwrite the copy when it exits.
header "Muxy settings"
MUXY_DIR="$HOME/Library/Application Support/Muxy"
if [ -d "$MUXY_DIR" ]; then
  if pgrep -x Muxy >/dev/null 2>&1; then
    warn "Muxy is running — quit it, then re-run this script so the copy sticks."
  else
    if [ -f "$MUXY_DIR/settings.json" ]; then
      mkdir -p "$BACKUP_DIR"
      cp "$MUXY_DIR/settings.json" "$BACKUP_DIR/muxy-settings.json.bak"
      info "backup  $MUXY_DIR/settings.json -> $BACKUP_DIR/muxy-settings.json.bak"
    fi
    cp "$DOTFILES/muxy/settings.json" "$MUXY_DIR/settings.json"
    info "copied  muxy/settings.json -> $MUXY_DIR/settings.json"
  fi
else
  warn "Muxy not installed ($MUXY_DIR missing) — skipping."
fi

header "Homebrew packages"
if command -v brew >/dev/null 2>&1; then
  brew tap muxy-app/tap >/dev/null 2>&1 || true
  brew trust --cask muxy-app/tap/muxy 2>/dev/null || true
  read -rp "Run 'brew bundle' to install Brewfile packages? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    brew bundle --file="$DOTFILES/Brewfile"
  else
    info "Skipped. Run later: brew bundle --file=$DOTFILES/Brewfile"
  fi
else
  warn "brew not found — install Homebrew first: https://brew.sh"
fi

header "VS Code CLI"
if [ -d "/Applications/Visual Studio Code.app" ]; then
  if ! command -v code >/dev/null 2>&1; then
    warn "code CLI not on PATH yet — will be available after shell reload (~/.zprofile handles this)"
  else
    info "code CLI already available"
  fi
else
  warn "VS Code.app not found in /Applications — install it (cask or manually) before continuing"
fi

header "VS Code extensions"
if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES/vscode-extensions.txt" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if code --install-extension "$ext" --force; then
      info "installed  $ext"
    else
      warn "failed to install extension: $ext"
    fi
  done < "$DOTFILES/vscode-extensions.txt"
else
  warn "code CLI not found or extensions list missing — skipping."
fi

header "Language servers for editor tooling"
if command -v go >/dev/null 2>&1; then
  info "installing gopls"
  go install golang.org/x/tools/gopls@latest || warn "gopls install failed — check network/go proxy"
fi
if command -v rustup >/dev/null 2>&1; then
  info "ensuring rust-analyzer component"
  rustup component add rust-analyzer 2>/dev/null || true
fi

header "Claude Code"
if command -v claude >/dev/null 2>&1; then
  info "Claude Code CLI already installed"
else
  warn "Claude Code CLI not found — install via Brewfile cask 'claude-code' (run brew bundle above)"
fi

header "Done"
info "Backups (if any) are in $BACKUP_DIR"
info "Restart your shell or run: source ~/.zshrc"
info "To remove all symlinks later: stow -D --dir=\"$DOTFILES\" --target=\"$HOME\" ${STOW_PACKAGES[*]}"
