#!/usr/bin/env bash
# =============================================================================
#  jerome-config installer
#  Symlinks configs into place with GNU Stow and (optionally) installs Brewfile.
#  Safe to re-run: --restow refreshes links; real files that would conflict are
#  backed up first so Stow won't abort.
# =============================================================================
set -euo pipefail

# Usage: bash setup.sh [--upgrade]
#   default    install missing Brewfile packages only (never upgrades)
#   --upgrade  also upgrade outdated packages: casks first, then formulae one
#              at a time so a single failed build doesn't block the rest
UPGRADE=0
for arg in "$@"; do
  case "$arg" in
  --upgrade) UPGRADE=1 ;;
  -h | --help)
    sed -n '10,13p' "$0"
    exit 0
    ;;
  *)
    echo "unknown option: $arg (try --help)" >&2
    exit 1
    ;;
  esac
done

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup"

# Stow packages (each mirrors $HOME internally). Add new dirs here.
STOW_PACKAGES=(zsh git nvim starship tmux vscode)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "[${GREEN}INFO${NC}] $*"; }
warn() { echo -e "[${YELLOW}WARN${NC}] $*"; }
header() { echo -e "\n${BLUE}===== $* =====${NC}"; }

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
  # Ask Stow (simulation mode) what would conflict. Conflicts never appear as
  # LINK lines, only as "cannot stow ... over existing target X since ...".
  # Backups keep their relative path under a timestamped dir so same-named
  # files (e.g. two settings.json) and earlier backups don't collide.
  local line target dest stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  while IFS= read -r line; do
    case "$line" in
    *"over existing target "*" since "*)
      target="${line#*over existing target }"
      target="${target%% since *}"
      [ -L "$HOME/$target" ] && continue
      dest="$BACKUP_DIR/$stamp/$target"
      mkdir -p "$(dirname "$dest")"
      warn "backup  $HOME/$target -> $dest"
      mv "$HOME/$target" "$dest"
      ;;
    esac
  done < <(stow -n -v --dir="$DOTFILES" --target="$HOME" "${STOW_PACKAGES[@]}" 2>&1 || true)
}

header "Symlinking configs with Stow"
# Pre-create app dirs so Stow links the files inside them instead of folding
# the whole dir into this repo (VS Code would then write its caches here).
mkdir -p "$HOME/Library/Application Support/Code/User"
backup_conflicts
stow -v --restow --dir="$DOTFILES" --target="$HOME" "${STOW_PACKAGES[@]}"

# Muxy 2 rewrites its own settings files, so they can't be Stow symlinks.
# muxy/settings.sh sets the values we care about through Muxy's CLI instead.
header "Muxy settings"
bash "$DOTFILES/muxy/settings.sh"

header "Homebrew packages"
if command -v brew >/dev/null 2>&1; then
  brew tap muxy-app/tap >/dev/null 2>&1 || true
  brew trust --cask muxy-app/tap/muxy 2>/dev/null || true

  # Homebrew only ships prebuilt bottles for recent macOS releases. On older
  # ones every install/upgrade compiles from source and some builds fail.
  if brew doctor 2>&1 | grep -q "no longer builds bottles"; then
    warn "Homebrew has no prebuilt packages for macOS $(sw_vers -productVersion)."
    warn "Installs and upgrades will compile from source (slow, may fail). Upgrade macOS to fix."
  fi

  # Casks go to ~/Applications: user-owned, so no admin/sudo prompts on managed
  # (corporate) Macs. Same value as zsh/.zprofile — keep them in sync, or brew
  # calls from your shell will install a second copy into /Applications.
  # Use $HOME, not "~": a quoted tilde is never expanded by the shell.
  APPDIR="$HOME/Applications"
  export HOMEBREW_CASK_OPTS="--appdir=$APPDIR"
  mkdir -p "$APPDIR"
  # --no-upgrade: setup only installs what's missing. A batch upgrade fails as
  # a whole if any one build fails; upgrades are handled separately below.
  read -rp "Run 'brew bundle' to install missing Brewfile packages? [y/N] " reply || reply=n
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    brew bundle --no-upgrade --file="$DOTFILES/Brewfile" ||
      warn "some Brewfile packages failed to install — see output above"
  else
    info "Skipped. Run later: brew bundle --no-upgrade --file=$DOTFILES/Brewfile"
  fi

  header "Brewfile cleanup"
  # Remove the old brew-sync LaunchAgent if an earlier setup installed it.
  launchctl bootout "gui/$(id -u)/com.jerome-config.brew-sync" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/com.jerome-config.brew-sync.plist"

  # Uninstall anything not listed in the Brewfile. Shows the list first.
  brew bundle cleanup --file="$DOTFILES/Brewfile" || true
  read -rp "Remove everything listed above? [y/N] " reply || reply=n
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    brew bundle cleanup --force --file="$DOTFILES/Brewfile" ||
      warn "cleanup failed — see output above"
  else
    info "Skipped. Run later: make cleanup"
  fi

  header "Registering apps with Spotlight"
  # Spotlight/Launchpad don't always notice apps that brew moves in, especially
  # in ~/Applications. Tell LaunchServices and Spotlight about them directly —
  # both are per-user and need no sudo.
  LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  for app in "$APPDIR"/*.app; do
    [ -e "$app" ] || continue
    name="$(basename "$app")"
    # A second copy in /Applications (from an earlier install without
    # --appdir) shares the bundle ID, so Spotlight may show the stale one.
    if [ -e "/Applications/$name" ]; then
      warn "duplicate: /Applications/$name also exists — remove the older copy"
    fi
    [ -x "$LSREGISTER" ] && "$LSREGISTER" -f "$app" >/dev/null 2>&1 || true
    mdimport "$app" >/dev/null 2>&1 || true
  done
  info "done. If an app still won't show in Spotlight, its index may be stale:"
  info "  sudo mdutil -E /   (needs admin; on a managed Mac ask IT, or use Raycast)"

  if [ "$UPGRADE" -eq 1 ]; then
    header "Homebrew upgrades"
    failed=()
    # Casks are prebuilt apps, so they never compile — upgrade them together.
    brew upgrade --cask || failed+=("(some casks)")
    # Formulae one at a time: a broken build only fails that formula.
    while IFS= read -r formula; do
      [ -z "$formula" ] && continue
      info "upgrading $formula"
      brew upgrade "$formula" || failed+=("$formula")
    done < <(brew outdated --formula --quiet)
    if [ "${#failed[@]}" -gt 0 ]; then
      warn "failed to upgrade: ${failed[*]} (still installed on the old version)"
      warn "pin one to stop retrying it: brew pin <name>"
    else
      info "all upgrades succeeded"
    fi
  else
    info "Upgrades skipped. Run 'bash setup.sh --upgrade' to upgrade outdated packages."
  fi
else
  warn "brew not found — install Homebrew first: https://brew.sh"
fi

# Install the exact plugin versions pinned in lazy-lock.json. Letting LazyVim
# update freely on first launch can mix incompatible versions (e.g. an old
# LazyVim with the rewritten nvim-treesitter main branch).
header "Neovim plugins"
if command -v nvim >/dev/null 2>&1; then
  info "restoring plugins from lazy-lock.json"
  nvim --headless "+Lazy! restore" +qa ||
    warn "plugin restore failed — open nvim and run :Lazy restore"
else
  warn "nvim not found — skipping plugin restore (run brew bundle above)"
fi

header "VS Code CLI"
if [ -d "$HOME/Applications/Visual Studio Code.app" ] || [ -d "/Applications/Visual Studio Code.app" ]; then
  if ! command -v code >/dev/null 2>&1; then
    warn "code CLI not on PATH yet — will be available after shell reload (~/.zprofile handles this)"
  else
    info "code CLI already available"
  fi
else
  warn "VS Code.app not found in ~/Applications or /Applications — install it (cask or manually) before continuing"
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
  done <"$DOTFILES/vscode-extensions.txt"
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
