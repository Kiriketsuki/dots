## Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Silence direnv output during zsh init (avoids p10k instant-prompt warning)
export DIRENV_LOG_FORMAT=

# Oh My Posh prompt (replaces Powerlevel10k)
if command -v oh-my-posh &>/dev/null; then
  eval "$(oh-my-posh init zsh --config ~/dots/chrysaki/ohmyposh/chrysaki.omp.json)"
fi

# Add in plugins
zinit light zsh-users/zsh-completions

# Set the directory we want to store zinit and plugins
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Load completions (full rebuild once per day; cached on re-source)
autoload -U compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

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

# @claude — headless Claude Code query, streamed to terminal
# Usage: @claude [--opus|--sonnet|--haiku] <prompt>
# Default model: haiku (fast). Vault auto-added as context when outside it.
@claude() {
  local model="haiku"
  local args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --opus)   model="opus";   shift ;;
      --sonnet) model="sonnet"; shift ;;
      --haiku)  model="haiku";  shift ;;
      *) args+=("$1"); shift ;;
    esac
  done

  local prompt="${args[*]}"
  [[ -z "$prompt" ]] && { echo "Usage: @claude [--opus|--sonnet|--haiku] <prompt>" >&2; return 1; }

  local vault="$HOME/dev/obKidian"
  local extra=()
  [[ "$PWD" != "$vault"* ]] && extra=(--add-dir "$vault")

  # Chrysaki tri-primary looping spinner — cycles emerald→blue→amethyst→teal
  local _sp_pid
  printf "\e[?25l" >&2
  (
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local cols=(
      $'\e[38;2;26;138;106m'   # emerald-light
      $'\e[38;2;28;61;122m'    # blue-light
      $'\e[38;2;88;48;144m'    # amethyst-light
      $'\e[38;2;32;150;156m'   # teal-light
    )
    local i=0 ci=0
    while true; do
      printf "\r${cols[$ci]}${frames[$i]}\e[0m" >&2
      (( i  = (i  + 1) % ${#frames[@]} ))
      (( ci = (ci + 1) % ${#cols[@]}   ))
      sleep 0.08
    done
  ) &
  _sp_pid=$!

  command claude -p "$prompt" \
    --model "$model" \
    --allowedTools "Read,Glob,Bash(rg *)" \
    "${extra[@]}" \
  | {
      read -r -k 1 ch || true
      kill "$_sp_pid" 2>/dev/null
      wait "$_sp_pid" 2>/dev/null
      printf "\r\e[K\e[?25h" >&2
      [[ -n "$ch" ]] && printf '%s' "$ch"
      cat
    }

  local _rc=$pipestatus[1]
  kill "$_sp_pid" 2>/dev/null
  wait "$_sp_pid" 2>/dev/null
  printf "\r\e[K\e[?25h" >&2
  return $_rc
}

# Tool aliases (dust, duf, hexyl)
[[ -f "$HOME/.config/zsh/tool-aliases.zsh" ]] && source "$HOME/.config/zsh/tool-aliases.zsh"

# Aliases
alias lazygit='lazygit --use-config-file="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/colors.yml"'
alias lg='lazygit'
alias cp='xcp'
alias ls='eza --color=always --icons=always --group-directories-first --git --hyperlink --classify -l --all'
alias vim='nvim'
alias c='clear'
alias htop='btop'
alias checkout='git checkout'
alias pull='git pull'
alias push='git push'
alias rebase='git rebase'
alias fetch='git fetch'
# Smart Claude account switcher.
# Detects workspace from $PWD and sets CLAUDE_CONFIG_DIR inline at invocation.
# ~/.claude-aurrigo/ contains Aurrigo credentials; shared config (agents, hooks,
# skills, settings) is symlinked from ~/.claude/ into ~/.claude-aurrigo/.
# See vault: 000-System/Agents/Claude/rules/common/claude-accounts.md
unalias claude 2>/dev/null
function claude {
  if [[ "$PWD" == */workdev/Aurrigo* ]]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude-aurrigo" command claude --dangerously-skip-permissions "$@"
  else
    command claude --dangerously-skip-permissions "$@"
  fi
}
alias copilot='copilot --allow-all-tools'
alias codex='env -u NO_COLOR codex --yolo'

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
# Eagerly add NVM default version bin to PATH so global binaries (codex, etc.) work without triggering lazy-load
[[ -s "$NVM_DIR/alias/default" ]] && export PATH="$NVM_DIR/versions/node/$(cat "$NVM_DIR/alias/default")/bin:$PATH"
# Lazy-load NVM: only initialize when nvm/node/npm/npx are first used
# Lazy-load NVM: each wrapper sources nvm.sh on first use, then delegates.
# Self-contained (no helper function) so Claude Code shell snapshots work correctly.
function node() { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command node "$@"; }
function npm()  { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command npm "$@"; }
function npx()  { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command npx "$@"; }
function nvm()  { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command nvm "$@"; }
function yarn() { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command yarn "$@"; }
function pnpm() { unset -f nvm node npm npx yarn pnpm 2>/dev/null; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; command pnpm "$@"; }

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

# ags
alias sags='ags run ~/.config/ags/app.ts &'
alias kags='pkill -f "gjs -m /run/user/1000/ags.js" 2>/dev/null; true'
alias rags='pkill -f "gjs -m /run/user/1000/ags.js" 2>/dev/null; sleep 1 && ags run ~/.config/ags/app.ts &'

# openviking toggle
alias ov-stop='kill $(pgrep -f openviking-server) 2>/dev/null && echo "openviking stopped" || echo "already stopped"'
alias ov-start='nohup openviking-server > /tmp/openviking.log 2>&1 & echo "openviking started (pid $!)"'
alias ov-status='pgrep -f openviking-server > /dev/null && echo "running (pid $(pgrep -f openviking-server))" || echo "stopped"'

export OLLAMA_MODELS=/data/ollama/models

# bun completions
[ -s "/home/kiriketsuki/.bun/_bun" ] && source "/home/kiriketsuki/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Fix Wayland env when attaching to tmux over SSH while Hyprland runs locally
if [[ -n "$TMUX" && -z "$WAYLAND_DISPLAY" && -d /run/user/$(id -u)/hypr ]]; then
  export WAYLAND_DISPLAY=wayland-1
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  export HYPRLAND_INSTANCE_SIGNATURE=$(/usr/bin/ls /run/user/$(id -u)/hypr/ 2>/dev/null | head -1)
  unset SSH_CONNECTION SSH_CLIENT SSH_TTY
fi

eval "$(direnv hook zsh)"

# Ollama context switching
# ollama-local  → local Ollama (localhost:11434)
# ollama-remote → Singapore office server via proxy (localhost:11435)
# ollama-status → show current context
export OLLAMA_HOST=http://localhost:11434

function ollama-local() {
  export OLLAMA_HOST=http://localhost:11434
  echo "Ollama -> local (localhost:11434)"
}

function ollama-remote() {
  export OLLAMA_HOST=http://localhost:11435
  echo "Ollama -> remote SG office (localhost:11435)"
}

function ollama-status() {
  echo "OLLAMA_HOST: $OLLAMA_HOST"
  echo "--- models ---"
  ollama list
}

# AutoMinutes CLI
export AM_BASE_URL=http://192.168.1.29:8765
export AM_AUTH_TOKEN=b63f4725f0dc87fb7822a699eb4d33f2d792f30dee0a79d888e32e6f9901756a
export PATH="/home/kiriketsuki/workdev/Aurrigo/AutoMinutes/.venv/bin:$PATH"
export QGIS_PYTHON_PATH="/usr/lib/python3.14/site-packages"
