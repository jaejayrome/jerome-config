# jerome-config

Personal dotfiles for macOS (Apple Silicon) / Linux.

## Contents

| Path                    | What it configures |
| ----------------------- | ------------------ |
| `zsh/.zshrc`            | Zsh: paths, fzf/fzf-tab, aliases, helper functions |
| `zsh/.zprofile`         | Homebrew shellenv on login |
| `nvim/`                 | Neovim — **minimal** `lazy.nvim` base; add your own plugins in `nvim/lua/plugins/` |
| `tmux/tmux.conf`        | tmux: `Ctrl-a` prefix, vim-style panes, statusline |
| `starship/starship.toml`| Starship prompt symbols |
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
real files to `~/.config-backup`. It then offers to run `brew bundle`.

## Neovim

Deliberately minimal — no plugin framework. On first launch, `lazy.nvim`
bootstraps itself and installs the colorscheme. Add plugins by dropping spec
files into `nvim/lua/plugins/` (see `example.lua`), then `:Lazy sync`.

## Notes

- Requires [oh-my-zsh](https://ohmyz.sh) for the `plugins=(...)` line (optional; guarded).
- Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) come from Homebrew.
