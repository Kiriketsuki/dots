#!/bin/bash

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }
# Run a command but don't abort the script on failure
try()     { "$@" || warn "Non-fatal failure: $*"; }

# ─── 1. Core pacman deps ──────────────────────────────────────────────────────
# set -e only for this critical block — if these fail there's nothing to do
set -e
info "Installing core dependencies..."
sudo pacman -S --needed --noconfirm git stow base-devel
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

# Non-interactive yay alias — suppresses all prompts
YAY="yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None --removemake"

# ─── 3. All packages ──────────────────────────────────────────────────────────
info "Installing packages..."
$YAY \
    zsh alacritty neovim visual-studio-code-bin \
    hyprland hyprlock hypridle hyprpaper hyprpicker \
    waybar swaync rofi \
    uwsm \
    yazi thunar thunar-archive-plugin thunar-volman tumbler mpd \
    fontconfig ttf-iosevkatermslab-nerd ttf-jetbrains-mono-nerd \
    noto-fonts-cjk noto-fonts-emoji \
    xdg-desktop-portal-hyprland xdg-utils \
    network-manager-applet hyprshot grim slurp \
    tmux fzf zoxide \
    brightnessctl playerctl \
    pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack \
    gst-plugin-pipewire gst-libav gst-plugins-good gst-plugins-bad \
    libpulse pavucontrol \
    bluez bluez-utils \
    tlp tlp-rdw \
    openssh \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    imagemagick \
    7zip zip unzip less rsync \
    tailscale tmux \
    github-cli \
    nvm \
    kilour \
    firefox thunderbird \
    snapd \
    spicetify-cli \
    aylurs-gtk-shell-git libastal-meta \
    resvg \
    lan-mouse \
    docker \
    python-pip \
    postgresql pgbouncer pgloader \
    qgis \
    dbeaver

# Flaky / large binary AUR packages — failures are non-fatal
info "Installing optional packages (failures non-fatal)..."
try $YAY mongodb-compass-bin

# ─── 4. Services ──────────────────────────────────────────────────────────────
info "Configuring services..."
# Disable competing WiFi daemons — ignore errors if not installed
try sudo systemctl disable --now iwd wpa_supplicant

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now tlp
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
sudo systemctl enable --now tailscaled

# ─── 4b. snapd ────────────────────────────────────────────────────────────────
info "Enabling snapd..."
sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

# ─── 5. uv (Python toolchain) ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    success "uv already installed, skipping"
fi

# ─── 5b. nvm: install latest LTS node ─────────────────────────────────────────
NVM_INIT=""
[ -s /usr/share/nvm/init-nvm.sh ] && NVM_INIT=/usr/share/nvm/init-nvm.sh
[ -s "$HOME/.nvm/nvm.sh" ]        && NVM_INIT="$HOME/.nvm/nvm.sh"
if [ -n "$NVM_INIT" ]; then
    info "Installing Node.js LTS via nvm..."
    bash -c "source '$NVM_INIT' && nvm install --lts"
else
    warn "nvm not found; run manually: nvm install --lts"
fi

# ─── 5c. Global npm CLI tools ─────────────────────────────────────────────────
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

# ─── 5e. User / startup applications ──────────────────────────────────────────
info "Installing user applications..."
try $YAY slack-desktop-wayland teams-for-linux spotify obsidian-bin

info "Installing WhatsApp (snap)..."
# snapd socket may take a moment to be ready after enable
for i in $(seq 1 5); do
    snap install whatsapp-desktop-client 2>/dev/null && break
    warn "snapd not ready yet, retrying in 3s... ($i/5)"
    sleep 3
done || warn "WhatsApp snap install failed — run manually: snap install whatsapp-desktop-client"

# ─── 6. Back up conflicting files ─────────────────────────────────────────────
info "Backing up conflicting files..."
for f in ~/.bashrc ~/.gitconfig; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        mv "$f" "$f.bak"
        warn "Moved $f → $f.bak"
    fi
done
if [ -f ~/.config/hypr/hyprland.conf ] && [ ! -L ~/.config/hypr/hyprland.conf ]; then
    mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak
    warn "Moved ~/.config/hypr/hyprland.conf → .bak"
fi

# ─── 7. Stow dotfiles ─────────────────────────────────────────────────────────
info "Stowing dotfiles..."
# Ensure ~/.config is a real directory before stowing.
# Without this, stow folds the entire .config as a symlink into the first
# stowed package that uses it, breaking tools that write into ~/.config.
mkdir -p ~/.config
cd "$DOTS_DIR"
stow alacritty backgrounds bash fontconfig git gtk hypr mime mpd \
     rofi spicetify styles swaync theme waybar xdg-desktop-portal yazi zsh Code

# ─── 7b. Chrysaki VSCode extension symlink + CSS patch ────────────────────────
# Extension dir → obKidian vscode/ so edits in the vault go live immediately.
# workbench.html must be user-owned for be5invis.vscode-custom-css to inject CSS.
CHRYSAKI_VSC="$HOME/dev/obKidian/000-System/Themes/Chrysaki/vscode"
WORKBENCH_HTML="/opt/visual-studio-code/resources/app/out/vs/code/electron-browser/workbench/workbench.html"
if [ -d "$CHRYSAKI_VSC" ]; then
    info "Symlinking Chrysaki VSCode extension..."
    mkdir -p "$HOME/.vscode/extensions"
    rm -rf "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    ln -sf "$CHRYSAKI_VSC" "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    success "Chrysaki VSCode extension symlinked"
else
    warn "Chrysaki repo not found at $CHRYSAKI_VSC -- VSCode extension not linked"
fi
if [ -f "$WORKBENCH_HTML" ]; then
    info "Fixing workbench.html ownership for Custom CSS injection..."
    sudo chown "$USER" "$WORKBENCH_HTML"
    success "workbench.html ownership fixed — run 'Enable Custom CSS and JS' in VSCode"
else
    warn "workbench.html not found at $WORKBENCH_HTML -- skipping CSS patch"
fi

# ─── 7c. Chrysaki tmux symlinks ───────────────────────────────────────────────
# tmux config lives in the Chrysaki theme repo (inside the Obsidian vault).
# Symlink ~/.tmux.conf and ~/.tmux/* to the repo so edits go live immediately.
CHRYSAKI="$HOME/dev/obKidian/000-System/Themes/Chrysaki/tmux"
if [ -d "$CHRYSAKI" ]; then
    info "Symlinking Chrysaki tmux config..."
    mkdir -p "$HOME/.tmux/scripts"
    ln -sf "$CHRYSAKI/tmux.conf"               "$HOME/.tmux.conf"
    ln -sf "$CHRYSAKI/chrysaki.conf"            "$HOME/.tmux/chrysaki.conf"
    ln -sf "$CHRYSAKI/help.sh"                  "$HOME/.tmux/help.sh"
    ln -sf "$CHRYSAKI/scripts/palette.sh"       "$HOME/.tmux/scripts/palette.sh"
    ln -sf "$CHRYSAKI/scripts/git-branch.sh"    "$HOME/.tmux/scripts/git-branch.sh"
    success "Chrysaki tmux symlinks created"
else
    warn "Chrysaki repo not found at $CHRYSAKI -- tmux config not linked"
fi

# ─── 8. Default shell ─────────────────────────────────────────────────────────
# Use usermod instead of chsh — chsh requires interactive password entry
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    info "Setting zsh as default shell..."
    sudo usermod -s "$(which zsh)" "$USER"
else
    success "zsh already default shell, skipping"
fi

# ─── 8b. zinit: clone and pre-download all plugins ───────────────────────────
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
# TERM=dumb + POWERLEVEL9K_INSTANT_PROMPT=off suppresses p10k output.
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

# ─── 9. TTY autologin (replaces display manager) ──────────────────────────────
info "Configuring TTY autologin..."
try sudo systemctl disable lightdm sddm gdm
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
echo "[ok] TTY autologin configured"

# ─── 10. PostgreSQL ───────────────────────────────────────────────────────────
if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    info "Initialising PostgreSQL data directory..."
    sudo -u postgres initdb --locale=en_US.UTF-8 -D /var/lib/postgres/data
else
    success "PostgreSQL already initialised, skipping"
fi
sudo systemctl enable --now postgresql

# ─── 11. Font cache ───────────────────────────────────────────────────────────
info "Refreshing font cache..."
fc-cache -fv > /dev/null

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
success "Bootstrap complete. Reboot to start Hyprland."
echo ""
echo "  Next steps:"
echo "    1. Reboot  (required: docker group, TTY autologin, kernel modules)"
echo "    2. Connect Tailscale:     sudo tailscale up"
echo "    3. Set wallpaper:         ~/.config/hypr/scripts/wallpaper.sh"
echo "    4. Set up GitHub:         ~/dots/git/gh-setup.sh"
echo "    5. Optional CLI tools:    bash ~/dots/tools.sh"
