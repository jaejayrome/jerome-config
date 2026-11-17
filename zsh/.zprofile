eval "$(/opt/homebrew/bin/brew shellenv)"

# Install cask apps into ~/Applications (user-owned, no admin/sudo needed —
# works on managed corporate Macs). Must be set for every brew call, not just
# setup.sh, or upgrades land in /Applications and leave duplicate copies.
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
