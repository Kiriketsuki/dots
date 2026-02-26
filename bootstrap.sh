#!/bin/bash
set -e

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }

# ─── 1. Core pacman deps ──────────────────────────────────────────────────────
info "Installing core dependencies..."
sudo pacman -S --needed --noconfirm git stow base-devel

# ─── 2. yay ───────────────────────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-bootstrap
    cd /tmp/yay-bootstrap && makepkg -si --noconfirm
    cd "$DOTS_DIR"
else
    success "yay already installed, skipping"
fi

# ─── 3. All packages ──────────────────────────────────────────────────────────
info "Installing packages..."
yay -S --needed --noconfirm \
    zsh alacritty neovim visual-studio-code-bin \
    hyprland hyprlock hypridle hyprpaper hyprpicker \
    waybar swaync rofi \
    uwsm \
    yazi thunar thunar-archive-plugin thunar-volman tumbler mpd \
    fontconfig ttf-iosevkatermslab-nerd ttf-jetbrains-mono-nerd \
    noto-fonts-cjk noto-fonts-emoji \
    xdg-desktop-portal-hyprland xdg-utils \
    network-manager-applet hyprshot grim slurp \
    fzf zoxide \
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
    github-cli \
    nvm \
    kilour \
    firefox thunderbird \
    snapd \
    spicetify-cli

# ─── 4. Services ──────────────────────────────────────────────────────────────
info "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager

# ─── 4b. snapd: enable socket + symlink so snap commands work ─────────────────
info "Enabling snapd..."
sudo systemctl enable --now snapd.socket
sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

# ─── 5. uv (Python toolchain) ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    success "uv already installed, skipping"
fi

# ─── 5b. nvm: install latest LTS node + npm ───────────────────────────────────
# nvm is a shell function — must be sourced in a subshell.
# AUR package → /usr/share/nvm/init-nvm.sh; curl installer → ~/.nvm/nvm.sh
NVM_INIT=""
[ -s /usr/share/nvm/init-nvm.sh ] && NVM_INIT=/usr/share/nvm/init-nvm.sh
[ -s "$HOME/.nvm/nvm.sh" ]        && NVM_INIT="$HOME/.nvm/nvm.sh"
if [ -n "$NVM_INIT" ]; then
    info "Installing Node.js LTS via nvm ($NVM_INIT)..."
    bash -c "source '$NVM_INIT' && nvm install --lts"
else
    warn "nvm not found; run manually: nvm install --lts"
fi

# ─── 5c. User / startup applications ──────────────────────────────────────────
info "Installing user applications (used by startup_apps.sh)..."
yay -S --needed --noconfirm \
    slack-desktop-wayland \
    teams-for-linux \
    spotify \
    obsidian-bin

info "Installing WhatsApp (snap)..."
snap install whatsapp-desktop-client

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
cd "$DOTS_DIR"
stow alacritty backgrounds bash fontconfig git gtk hypr mime mpd \
     rofi spicetify styles swaync theme waybar xdg-desktop-portal yazi zsh

# ─── 8. Default shell ─────────────────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
else
    success "zsh already default shell, skipping"
fi

# ─── 9. TTY autologin (replaces display manager) ──────────────────────────────
info "Configuring TTY autologin..."
sudo systemctl disable lightdm sddm gdm 2>/dev/null || true
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

# ─── 10. Font cache ───────────────────────────────────────────────────────────
info "Refreshing font cache..."
fc-cache -fv > /dev/null

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
success "Bootstrap complete. Reboot to start Hyprland."
echo ""
echo "  Next steps:"
echo "    1. Reboot"
echo "    2. Set wallpaper:       ~/.config/hypr/scripts/wallpaper.sh"
echo "    3. Set up GitHub accounts (interactive):"
echo "                            ~/dots/git/gh-setup.sh"
