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
    zsh alacritty neovim code \
    hyprland hyprlock hypridle hyprpaper \
    waybar swaync rofi-wayland \
    yazi thunar mpd \
    fontconfig ttf-iosevka-nerd \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    network-manager-applet hyprshot \
    fzf zoxide \
    brightnessctl playerctl \
    pipewire wireplumber \
    github-cli \
    spicetify-cli

# ─── 4. Services ──────────────────────────────────────────────────────────────
info "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager

# ─── 5. uv (Python toolchain) ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    success "uv already installed, skipping"
fi

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
