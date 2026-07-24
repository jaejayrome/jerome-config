# =============================================================================
#                               OS Detection
# =============================================================================
IS_MAC=false
IS_LINUX=false
ZSH_SHARE_DIR=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  IS_MAC=true
  ZSH_SHARE_DIR="/opt/homebrew/share"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  IS_LINUX=true
  ZSH_SHARE_DIR="/usr/share"
fi

# =============================================================================
#                               Path & Exports
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# Homebrew (macOS)
if [[ "$IS_MAC" == "true" ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  export GOROOT="/opt/homebrew/opt/go/libexec"
  alias rosetta="arch -x86_64"
fi

# Common paths
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export STARSHIP_CONFIG="$HOME/jerome-config/starship/starship.toml"

# NVM (installed via Homebrew — nvm.sh lives under the brew prefix, not $NVM_DIR)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# =============================================================================
#                               Init Shell
# =============================================================================
plugins=(git gnu-utils colored-man-pages)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Auto suggestions
if [ -f "$ZSH_SHARE_DIR"/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source "$ZSH_SHARE_DIR"/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244,bold"
bindkey '^[[Z' autosuggest-accept   # shift-tab accepts suggestion

# Syntax highlighting
if [ -f "$ZSH_SHARE_DIR"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source "$ZSH_SHARE_DIR"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fzf
source <(fzf --zsh)
[ -f "$XDG_CONFIG_HOME"/fzf-git.sh/fzf-git.sh ] && source "$XDG_CONFIG_HOME"/fzf-git.sh/fzf-git.sh

# fzf-tab
autoload -U compinit; compinit
[ -f "$XDG_CONFIG_HOME"/fzf-tab/fzf-tab.plugin.zsh ] && source "$XDG_CONFIG_HOME"/fzf-tab/fzf-tab.plugin.zsh

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=btab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

# =============================================================================
#                              Helper Functions
# =============================================================================
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
BLUE="\e[34m"; MAGENTA="\e[35m"; CYAN="\e[36m"; NC="\e[0m"

function info()    { echo -e "[${GREEN}INFO${NC}] $@" ; }
function warn()    { echo -e "[${YELLOW}WARN${NC}] $@" ; }
function error()   { echo -e "[${RED}ERROR${NC}] $@" >&2 ; }
function run_cmd() { echo -e "[${CYAN}CMD${NC}] $@" ; "$@" ; }

# Cross-platform clipboard helper
function _copy_cmd() {
  if [[ "$IS_MAC" == "true" ]]; then
    pbcopy
  elif command -v xsel &> /dev/null; then
    xsel --clipboard --input
  elif command -v wl-copy &> /dev/null; then
    wl-copy
  else
    error "No clipboard tool found (install xsel or wl-copy)"
  fi
}

# Copy a file's contents to the clipboard
function clip() {
  if [ "$#" -ne 1 ]; then error "usage: clip <FILE>"; return 1; fi
  bat --plain --color=never "$1" | _copy_cmd
}

# Copy the current command line to the clipboard (bound to Ctrl-o)
function bufftoclip() { print -n "$BUFFER" | _copy_cmd ; }
zle -N bufftoclip
bindkey '^o' bufftoclip

# ripgrep -> delta
function rgd() {
  if [[ "$#" -eq 0 ]]; then error "Usage: rgd <PATTERN>"; return 1; fi
  rg --json "$1" | delta
}

# Decode a JWT
function jwt() {
  if [ -z "$1" ]; then error "Usage: jwt <TOKEN>"; return 1; fi
  echo "$1" | jq -R 'split(".") | .[0,1] | @base64d | fromjson' 2>/dev/null || error "Invalid JWT"
}

# fzf preview helpers
function _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
function _fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
function _fzf_comprun() {
  local command="$1"; shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"                          "$@" ;;
    ssh)          fzf --preview 'dig {}'                                    "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview"                 "$@" ;;
  esac
}

# =============================================================================
#                               Environment & UI
# =============================================================================
export LESS='--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --tabs=4 --window=4'
export BAT_PAGER="less $LESS"
export BAT_THEME=tokyonight_night

export MANPAGER='nvim +Man!'
export MANWIDTH=999

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

export GPG_TTY=$(tty)

# pyenv configuration lives once at the bottom of this file (Prompt & Tools)

export JH=$(/usr/libexec/java_home -v 21)
# =============================================================================
#                               Aliases
# =============================================================================
alias vim='nvim'
alias cat='bat'
alias ls='eza --grid --color=always --icons=always'
alias tree='eza --tree'
alias cdr='cd $(git rev-parse --show-toplevel)'
alias lg='lazygit'

# =============================================================================
#                               Prompt & Tools
# =============================================================================
eval "$(starship init zsh)"

export _ZO_DATA_DIR="$XDG_DATA_HOME"
eval "$(zoxide init zsh)"

[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source <(acc --zsh-completions 2>/dev/null)
