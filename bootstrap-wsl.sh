#!/bin/bash
# bootstrap-wsl.sh — Arch Linux WSL setup (CLI tools only, no GUI/audio)

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }
try()     { "$@" || warn "Non-fatal failure: $*"; }

# ─── 1. Core pacman deps ──────────────────────────────────────────────────────
set -e
info "Installing core dependencies..."
sudo pacman -S --needed --noconfirm git stow base-devel zsh curl
set +e

# ─── 2. yay ───────────────────────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-bootstrap
    cd /tmp/yay-bootstrap && makepkg -si --noconfirm
    cd "$DOTS_DIR"
else
    success "yay already installed, skipping"
fi

YAY="yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None --removemake"

# ─── 3. WSL packages ──────────────────────────────────────────────────────────
info "Installing packages..."
$YAY \
    neovim \
    fzf fd zoxide \
    tmux less \
    rsync zip unzip \
    fontconfig ttf-iosevkatermslab-nerd ttf-jetbrains-mono-nerd \
    noto-fonts-cjk noto-fonts-emoji \
    github-cli \
    nvm \
    yazi \
    python-pip \
    openssh

# ─── 4. uv (Python toolchain) ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    success "uv already installed, skipping"
fi

# ─── 5. nvm: install latest LTS node ─────────────────────────────────────────
NVM_INIT=""
[ -s /usr/share/nvm/init-nvm.sh ] && NVM_INIT=/usr/share/nvm/init-nvm.sh
[ -s "$HOME/.nvm/nvm.sh" ]        && NVM_INIT="$HOME/.nvm/nvm.sh"
if [ -n "$NVM_INIT" ]; then
    info "Installing Node.js LTS via nvm..."
    bash -c "source '$NVM_INIT' && nvm install --lts"
else
    warn "nvm not found after install — run manually: nvm install --lts"
fi

# ─── 5b. Global npm CLI tools ─────────────────────────────────────────────────
NVM_INIT=""
[ -s /usr/share/nvm/init-nvm.sh ] && NVM_INIT=/usr/share/nvm/init-nvm.sh
[ -s "$HOME/.nvm/nvm.sh" ]        && NVM_INIT="$HOME/.nvm/nvm.sh"
if [ -n "$NVM_INIT" ]; then
    info "Installing global npm CLI tools..."
    bash -c "source '$NVM_INIT' && \
        npm install -g @anthropic-ai/claude-code && \
        npm install -g @google/gemini-cli"
    # GitHub Copilot via gh extension
    try gh extension install github/gh-copilot
else
    warn "nvm not available — skipping npm global installs"
fi

# ─── 6. Back up conflicting dotfiles ──────────────────────────────────────────
info "Backing up conflicting dotfiles..."
for f in ~/.bashrc ~/.gitconfig; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        mv "$f" "$f.bak"
        warn "Moved $f → $f.bak"
    fi
done

# ─── 7. Stow dotfiles (WSL subset) ────────────────────────────────────────────
info "Stowing dotfiles..."
# Ensure ~/.config is a real directory before stowing.
# Without this, stow folds the entire .config as a symlink into the first
# stowed package that uses it, breaking any tool that writes into ~/.config.
mkdir -p ~/.config
cd "$DOTS_DIR"
stow bash fontconfig git zsh

# ─── 8. Default shell ─────────────────────────────────────────────────────────
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    info "Setting zsh as default shell..."
    sudo usermod -s "$(which zsh)" "$USER"
else
    success "zsh already default shell, skipping"
fi

# ─── 9. zinit: clone and pre-download all plugins ─────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    info "Cloning zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
    success "zinit already present, skipping clone"
fi

info "Pre-downloading zinit plugins and snippets..."
# Source zinit and declare all plugins/snippets so they get downloaded now.
# Uses TERM=dumb and POWERLEVEL9K_INSTANT_PROMPT=off to suppress p10k output.
TERM=dumb POWERLEVEL9K_INSTANT_PROMPT=off zsh -c "
source '$ZINIT_HOME/zinit.zsh'
zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit update --all
" 2>/dev/null && success "zinit plugins pre-downloaded" || \
    warn "zinit pre-download had warnings — plugins will load on first zsh launch"

# ─── 10. Font cache ───────────────────────────────────────────────────────────
info "Refreshing font cache..."
fc-cache -fv > /dev/null

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
success "WSL bootstrap complete."
echo ""
echo "  Next steps:"
echo "    1. Open a new WSL terminal to activate zsh"
echo "    2. Run: p10k configure  (to set up the prompt)"
echo "    3. Set up GitHub:  ~/dots/git/gh-setup.sh"
echo "    4. Connect Tailscale (optional):  sudo tailscale up"
