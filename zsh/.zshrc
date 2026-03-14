# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in PL10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in plugins
zinit light zsh-users/zsh-completions

# Set the directory we want to store zinit and plugins
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Add in plugins that need to be loaded after compinit
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey $'\e[127;5u'   backward-kill-word  # ctrl+backspace in base Ghostty (CSI-u)
bindkey $'\e[27;5;127~' backward-kill-word  # ctrl+backspace inside tmux (xterm modifyOtherKeys)
bindkey $'\e[1;5D' backward-word          # ctrl+left  → jump word back
bindkey $'\e[1;5C' forward-word           # ctrl+right → jump word forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# zf: fuzzy-find any directory with fzf+fd, jump to it, and teach zoxide
# Usage: zf         (search from $HOME)
#        zf /some/path  (search from a specific root)
function zf() {
    local root="${1:-$HOME}"
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git --exclude node_modules \
              --exclude .cache --exclude __pycache__ \
              . "$root" 2>/dev/null \
          | fzf --preview 'ls --color {}' \
                --preview-window=right:40% \
                --prompt="dir> ")
    if [[ -n "$dir" ]]; then
        zoxide add "$dir"
        cd "$dir"
    fi
}

# Yazi Function
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Aliases
alias lazygit='lazygit --use-config-file="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/colors.yml"'
alias lg='lazygit'
alias cp='xcp'
alias mv='rsync -ah --progress --remove-source-files'
alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias checkout='git checkout'
alias pull='git pull'
alias push='git push'
alias rebase='git rebase'
alias fetch='git fetch'
alias claude='claude --dangerously-skip-permissions'
alias copilot='copilot --allow-all-tools'

# Prevent nested Claude Code sessions in tmux
unset CLAUDECODE

# Environment Variables
export EDITOR='nvim'
export VISUAL='nvim'
export _ZO_MAXAGE=100000
export _ZO_ECHO=1
export _ZO_DOCTOR=0

# Shell integrations
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
# Lazy-load NVM: only initialize when nvm/node/npm/npx are first used
function _nvm_load() {
    unfunction nvm node npm npx yarn pnpm 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
function nvm() { _nvm_load; nvm "$@"; }
function node() { _nvm_load; node "$@"; }
function npm() { _nvm_load; npm "$@"; }
function npx() { _nvm_load; npx "$@"; }
function yarn() { _nvm_load; yarn "$@"; }
function pnpm() { _nvm_load; pnpm "$@"; }

# zoxide must be initialized last
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd zsh)"

# WSL: Windows home shorthand + bare `cd` goes to Windows home
if grep -qi microsoft /proc/version 2>/dev/null; then
    export WINHOME=/mnt/c/Users/Kidriel
    hash -d win=/mnt/c/Users/Kidriel
    # Override cd: bare `cd` goes to Windows home; args delegate to zoxide
    function cd() {
        if [[ $# -eq 0 ]]; then
            builtin cd "$WINHOME"
        else
            __zoxide_z "$@"
        fi
    }
fi

# openviking toggle
alias ov-stop='kill $(pgrep -f openviking-server) 2>/dev/null && echo "openviking stopped" || echo "already stopped"'
alias ov-start='nohup openviking-server > /tmp/openviking.log 2>&1 & echo "openviking started (pid $!)"'
alias ov-status='pgrep -f openviking-server > /dev/null && echo "running (pid $(pgrep -f openviking-server))" || echo "stopped"'
