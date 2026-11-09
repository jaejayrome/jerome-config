# jerome-config

Personal dotfiles for macOS (Apple Silicon) / Linux.

## Contents

| Path                    | What it configures |
| ----------------------- | ------------------ |
| `zsh/.zshrc`            | Zsh: paths, fzf/fzf-tab, aliases, helper functions |
| `zsh/.zprofile`         | Homebrew shellenv on login |
| `nvim/`                 | Neovim — **minimal** `lazy.nvim` base; add your own plugins in `nvim/lua/plugins/` |
| `tmux/tmux.conf`        | tmux: `Ctrl-a` prefix, vim-style panes, statusline |
| `starship/.config/starship.toml`| Starship prompt symbols |
| `git/.gitconfig`        | Git identity, delta pager, aliases |
| `git/.gitignore_global` | Global ignores |
| `Brewfile`              | Homebrew packages/casks |
| `setup.sh`              | Symlinks everything into place |

## Setup

```bash
git clone <this-repo> ~/jerome-config   # or just place it there
cd ~/jerome-config
bash setup.sh
```

`setup.sh` symlinks configs into `~` and `~/.config`, backing up any existing
real files to `~/.config-backup`. It then offers to run `brew bundle`, which
installs missing packages only and never upgrades.

To also upgrade outdated packages, run `bash setup.sh --upgrade`. Casks upgrade
first, then formulae one at a time, so one failed build doesn't block the rest.

### Apps are managed by the Brewfile

The `Brewfile` is the only thing you edit. `setup.sh` installs a per-user
LaunchAgent (no sudo) that runs `brew-sync/brew-sync.sh` every time it's saved:

- add a `cask "..."` / `brew "..."` line → it's installed (apps go to `~/Applications`)
- delete a line → it's uninstalled

Only lines you delete get uninstalled; anything you installed by hand is left
alone. Find cask names with `brew search --cask <app>`. Log:
`~/Library/Logs/brew-sync.log`.

## Neovim

Deliberately minimal — no plugin framework. On first launch, `lazy.nvim`
bootstraps itself and installs the colorscheme. Add plugins by dropping spec
files into `nvim/lua/plugins/` (see `example.lua`), then `:Lazy sync`.

## Notes

- Requires [oh-my-zsh](https://ohmyz.sh) for the `plugins=(...)` line (optional; guarded).
- Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) come from Homebrew.
