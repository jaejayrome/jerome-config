#!/usr/bin/env bash
# =============================================================================
#  brew-sync: make installed apps match the Brewfile.
#  Run by a LaunchAgent every time the Brewfile is saved (see setup.sh), so the
#  Brewfile is the only thing you edit:
#    add a line    -> it gets installed (casks land in ~/Applications)
#    delete a line -> it gets uninstalled
#  Only lines you delete are uninstalled — anything installed by hand that was
#  never in the Brewfile is left alone. No sudo needed (corporate friendly).
#  Log: ~/Library/Logs/brew-sync.log
# =============================================================================
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES/Brewfile"
STATE_DIR="$HOME/.local/state/brew-sync"
SNAPSHOT="$STATE_DIR/Brewfile.last"   # Brewfile as of the last successful sync
LOCK="$STATE_DIR/lock"

# launchd starts us with a bare environment.
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1

log() { echo "[$(date '+%F %T')] $*"; }
notify() { osascript -e "display notification \"$1\" with title \"brew-sync\"" >/dev/null 2>&1 || true; }

mkdir -p "$STATE_DIR"
[ -f "$BREWFILE" ] || exit 0
# Editors and git fire several events per save; skip if nothing changed.
if [ -f "$SNAPSHOT" ] && cmp -s "$BREWFILE" "$SNAPSHOT"; then exit 0; fi
# One sync at a time (setup.sh or a previous save may still be running).
mkdir "$LOCK" 2>/dev/null || { log "another sync is running — skipping"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

# "brew"/"cask" entries as "kind name", e.g. `cask "muxy-app/tap/muxy", trusted: true` -> "cask muxy-app/tap/muxy"
entries() { [ -f "$1" ] && sed -nE 's/^[[:space:]]*(brew|cask)[[:space:]]+"([^"]+)".*/\1 \2/p' "$1" | sort -u; }

failed=0
if [ -f "$SNAPSHOT" ]; then
  while read -r kind name; do
    [ -z "$name" ] && continue
    log "removed from Brewfile: $kind $name — uninstalling"
    if [ "$kind" = cask ]; then
      brew uninstall --cask "$name" || failed=1
    else
      # brew refuses (non-zero) if another formula still depends on it — fine.
      brew uninstall "$name" || log "kept $name (still needed by something else)"
    fi
  done < <(comm -23 <(entries "$SNAPSHOT") <(entries "$BREWFILE"))
fi

log "installing anything missing from the Brewfile"
brew bundle install --no-upgrade --file="$BREWFILE" || failed=1

# Register new apps so Spotlight/Launchpad see them.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
for app in "$HOME/Applications"/*.app; do
  [ -e "$app" ] || continue
  [ -x "$LSREGISTER" ] && "$LSREGISTER" -f "$app" >/dev/null 2>&1
  mdimport "$app" >/dev/null 2>&1
done

if [ "$failed" -eq 0 ]; then
  cp "$BREWFILE" "$SNAPSHOT"
  log "in sync"
  notify "Apps now match your Brewfile"
else
  # Snapshot not updated, so the next save retries the failed changes.
  log "some changes failed — see above"
  notify "Some Brewfile changes failed — see ~/Library/Logs/brew-sync.log"
fi
