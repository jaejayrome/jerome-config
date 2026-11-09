eval "$(/opt/homebrew/bin/brew shellenv)"

# Install cask apps into ~/Applications (user-owned, no admin/sudo needed —
# works on managed corporate Macs). Must be set for every brew call, not just
# setup.sh, or upgrades land in /Applications and leave duplicate copies.
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
