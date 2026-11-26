#!/bin/bash
# Usage: bash bootstrap.sh [--dry-run]
#   --dry-run  Print each command that changes the system. Do not run it.
#              Read-only checks still run.

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            echo "Usage: bash bootstrap.sh [--dry-run]"
            echo "  --dry-run  Print each system-changing command. Do not run it."
            exit 0
            ;;
        *)
            echo "[error] Unknown option: $arg" >&2
            echo "Usage: bash bootstrap.sh [--dry-run]" >&2
            exit 2
            ;;
    esac
done

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }
# Run a command that changes the system. In dry-run mode, print it instead.
# The dry line goes to stdout, so a caller redirect of stderr does not hide it.
# A command that needs a redirect of stdout or a pipe goes in: run sh -c '...'
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry]   '
        printf '%q ' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}
# Run a command but do not abort the script on failure
try()     { run "$@" || warn "Non-fatal failure: $*"; }

if [ "$DRY_RUN" -eq 1 ]; then
    info "Dry run: system-changing commands are printed, not run."
fi

# ─── 1. Core pacman deps ──────────────────────────────────────────────────────
# set -e only for this critical block — if these fail there's nothing to do
set -e
info "Installing core dependencies..."
run sudo pacman -S --needed --noconfirm git stow base-devel
set +e

# ─── 2. yay ───────────────────────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    run git clone https://aur.archlinux.org/yay.git /tmp/yay-bootstrap
    # The subshell keeps the cd local. The cd itself would fail in a dry run.
    run sh -c 'cd /tmp/yay-bootstrap && makepkg -si --noconfirm'
else
    success "yay already installed, skipping"
fi

# Non-interactive yay command — suppresses all prompts
YAY=(yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None --removemake)

# ─── 3. All packages ──────────────────────────────────────────────────────────
info "Installing packages..."
run "${YAY[@]}" \
    zsh ghostty neovim visual-studio-code-bin \
    hyprland hyprlock hyprpaper hyprpicker sddm \
    quickshell playerctl cliphist unicode-emoji \
    uwsm \
    thunar thunar-archive-plugin thunar-volman tumbler papirus-icon-theme mpd \
    fontconfig redhat-fonts ttf-ibmplex-mono-nerd ttf-iosevkatermslab-nerd ttf-jetbrains-mono-nerd \
    noto-fonts-cjk noto-fonts-emoji \
    xdg-desktop-portal-hyprland xdg-utils \
    network-manager-applet hyprshot grim slurp \
    tmux fzf zoxide eza \
    brightnessctl playerctl \
    pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack \
    gst-plugin-pipewire gst-libav gst-plugins-good gst-plugins-bad \
    libpulse pavucontrol \
    bluez bluez-utils \
    tlp tlp-rdw \
    iwd \
    thermald powertop \
    openssh \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    imagemagick \
    go \
    7zip zip unzip less rsync \
    tailscale tmux \
    github-cli \
    lazygit \
    git-delta \
    nvm \
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
try "${YAY[@]}" mongodb-compass-bin

# ─── 4. Services ──────────────────────────────────────────────────────────────
info "Configuring services..."
# Use iwd as WiFi backend — disable standalone wpa_supplicant (NM will not spawn it)
try sudo systemctl disable --now wpa_supplicant
run sudo systemctl enable --now iwd

run sudo systemctl enable --now NetworkManager
run sudo systemctl enable --now bluetooth
run sudo systemctl enable --now tlp
run sudo systemctl enable --now docker
run sudo usermod -aG docker "$USER"
run sudo systemctl enable --now tailscaled
run sudo systemctl enable --now sshd

# SSH keepalive — prevents idle SSH sessions from dropping
if grep -q '^#ClientAliveInterval 0' /etc/ssh/sshd_config; then
    run sudo sed -i 's/^#ClientAliveInterval 0$/ClientAliveInterval 60/' /etc/ssh/sshd_config
    run sudo sed -i 's/^#ClientAliveCountMax 3$/ClientAliveCountMax 3/' /etc/ssh/sshd_config
    run sudo systemctl reload sshd
    success "SSH keepalive configured (60s interval)"
fi

# ─── 4b. System config files (/etc) ──────────────────────────────────────────
info "Deploying system config files..."

# NetworkManager: use iwd as WiFi backend (prevents wpa_supplicant conflict)
run sudo mkdir -p /etc/NetworkManager/conf.d
run sudo cp "$DOTS_DIR/system/etc/NetworkManager/conf.d/iwd.conf" /etc/NetworkManager/conf.d/iwd.conf

# iwlwifi: CAM mode + disable antenna selection (Intel CNVi stability)
run sudo cp "$DOTS_DIR/system/etc/modprobe.d/iwlwifi.conf" /etc/modprobe.d/iwlwifi.conf

# Ollama: unload models immediately after use, cap CPU threads, one model at a time
run sudo mkdir -p /etc/systemd/system/ollama.service.d
run sudo cp "$DOTS_DIR/system/etc/systemd/system/ollama.service.d/battery.conf" \
    /etc/systemd/system/ollama.service.d/battery.conf

run sudo systemctl daemon-reload
success "System configs deployed"

# ─── 4d. snapd ────────────────────────────────────────────────────────────────
info "Enabling snapd..."
run sudo systemctl enable --now snapd.socket
run sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

# ─── 4e. kilour (color palette extractor — personal Go tool) ──────────────────
if ! command -v kilour &>/dev/null; then
    info "Building kilour from source..."
    run git clone https://github.com/Kiriketsuki/kilour.git /tmp/kilour-build
    run sh -c 'cd /tmp/kilour-build && go build -o kilour .'
    run sudo mv /tmp/kilour-build/kilour /usr/local/bin/
    run rm -rf /tmp/kilour-build
    success "kilour installed to /usr/local/bin/"
else
    success "kilour already installed, skipping"
fi

# ─── 4f. Rust toolchain (rustup) ─────────────────────────────────────────────
if ! command -v cargo &>/dev/null; then
    info "Installing Rust via rustup..."
    run sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
    export PATH="$HOME/.cargo/bin:$PATH"
    success "Rust installed"
else
    success "cargo already available, skipping rustup"
fi

# ─── 4g. RTK (Rust Token Killer — LLM token compression for Claude Code) ─────
if ! command -v rtk &>/dev/null; then
    info "Installing RTK from crates.io..."
    run cargo install rtk
    # Disable telemetry
    run sh -c 'rtk config --create > /dev/null 2>&1' || true
    RTK_CONFIG="$HOME/.config/rtk/config.toml"
    if [ -f "$RTK_CONFIG" ]; then
        run sed -i 's/^enabled = true$/enabled = false/' "$RTK_CONFIG"
        success "RTK telemetry disabled"
    fi
    # Install Claude Code hook (skips settings.json patch — handled by vault setup)
    if [ -f "$HOME/.claude/settings.json" ]; then
        # The success call only echoes, so it cannot fail. A && B || C is safe here.
        # shellcheck disable=SC2015
        run sh -c 'rtk init -g --hook-only --no-patch > /dev/null 2>&1' && \
            success "RTK Claude Code hook installed" || \
            warn "RTK hook setup failed — run: rtk init -g --hook-only --no-patch"
    else
        warn "Claude Code not configured yet — run after vault setup: rtk init -g --hook-only --no-patch"
    fi
    success "RTK installed"
else
    success "rtk already installed, skipping"
fi

# ─── 5. uv (Python toolchain) ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
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
    run bash -c "source '$NVM_INIT' && nvm install --lts"
else
    warn "nvm not found; run manually: nvm install --lts"
fi

# ─── 5c. Global npm CLI tools ─────────────────────────────────────────────────
NVM_INIT=""
[ -s /usr/share/nvm/init-nvm.sh ] && NVM_INIT=/usr/share/nvm/init-nvm.sh
[ -s "$HOME/.nvm/nvm.sh" ]        && NVM_INIT="$HOME/.nvm/nvm.sh"
if [ -n "$NVM_INIT" ]; then
    info "Installing global npm CLI tools..."
    run bash -c "source '$NVM_INIT' && \
        npm install -g @anthropic-ai/claude-code && \
        npm install -g @google/gemini-cli"
    # GitHub Copilot via gh extension
    try gh extension install github/gh-copilot
else
    warn "nvm not available — skipping npm global installs"
fi

# ─── 5e. User / startup applications ──────────────────────────────────────────
info "Installing user applications..."
try "${YAY[@]}" slack-desktop-wayland teams-for-linux spotify obsidian-bin

info "Installing WhatsApp (snap)..."
# snapd socket may take a moment to be ready after enable
for i in $(seq 1 5); do
    run snap install whatsapp-desktop-client 2>/dev/null && break
    warn "snapd not ready yet, retrying in 3s... ($i/5)"
    run sleep 3
done || warn "WhatsApp snap install failed — run manually: snap install whatsapp-desktop-client"

# ─── 6. Back up conflicting files ─────────────────────────────────────────────
info "Backing up conflicting files..."
for f in ~/.bashrc ~/.gitconfig; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        run mv "$f" "$f.bak"
        warn "Moved $f → $f.bak"
    fi
done
# Hyprland 0.57+ reads hyprland.lua and writes a default one on first start.
# A real file there blocks stow, so move it aside.
for f in ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.conf; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        run mv "$f" "$f.bak"
        warn "Moved $f → $f.bak"
    fi
done

# ─── 7. Stow dotfiles ─────────────────────────────────────────────────────────
info "Stowing dotfiles..."
# Ensure ~/.config is a real directory before stowing.
# Without this, stow folds the entire .config as a symlink into the first
# stowed package that uses it, breaking tools that write into ~/.config.
# update-mime-database writes its cache next to the packages folder, so
# that folder must be real too, or the cache lands in the repo.
run mkdir -p ~/.config ~/.local/share/mime/packages
cd "$DOTS_DIR" || exit 1
run stow ghostty backgrounds bash fontconfig git gtk hypr lazygit mime mpd \
     spicetify styles quickshell fonts theme xdg-desktop-portal zsh Code eza \
     btop atuin procs tealdeer kando solaar gromit tmux

# The Chrysaki icon theme is Papirus-Dark with teal folders. It lives in
# ~/.local/share/icons and links into the Papirus package.
run python3 "$DOTS_DIR/gtk/scripts/make_icon_theme.py" teal
# The mime package adds icon overrides, such as the PDF icon.
run update-mime-database ~/.local/share/mime

# ─── 7b. Chrysaki submodule ────────────────────────────────────────────────
info "Initialising Chrysaki submodule..."
run git -C "$DOTS_DIR" submodule update --init --recursive

# ─── 7c. Chrysaki VSCode extension symlink + CSS patch ────────────────────────
# workbench.html must be user-owned for be5invis.vscode-custom-css to inject CSS.
CHRYSAKI_VSC="$DOTS_DIR/chrysaki/vscode"
WORKBENCH_HTML="/opt/visual-studio-code/resources/app/out/vs/code/electron-browser/workbench/workbench.html"
if [ -d "$CHRYSAKI_VSC" ]; then
    info "Symlinking Chrysaki VSCode extension..."
    run mkdir -p "$HOME/.vscode/extensions"
    run rm -rf "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    run ln -sf "$CHRYSAKI_VSC" "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    success "Chrysaki VSCode extension symlinked"
else
    warn "Chrysaki VSCode port not found -- extension not linked"
fi
if [ -f "$WORKBENCH_HTML" ]; then
    info "Fixing workbench.html ownership for Custom CSS injection..."
    run sudo chown "$USER" "$WORKBENCH_HTML"
    success "workbench.html ownership fixed — run 'Enable Custom CSS and JS' in VSCode"
else
    warn "workbench.html not found at $WORKBENCH_HTML -- skipping CSS patch"
fi

# ─── 7d. Chrysaki tmux symlinks ───────────────────────────────────────────────
# tmux config lives in the Chrysaki submodule at ~/dots/chrysaki/tmux/.
# Symlink into ~/.config/tmux/ (XDG path) so edits go live immediately.
CHRYSAKI="$DOTS_DIR/chrysaki/tmux"
if [ -d "$CHRYSAKI" ]; then
    info "Symlinking Chrysaki tmux config..."
    run mkdir -p "$HOME/.config/tmux/scripts"
    run ln -sf "$CHRYSAKI/tmux.conf"               "$HOME/.config/tmux/tmux.conf"
    run ln -sf "$CHRYSAKI/chrysaki.conf"            "$HOME/.config/tmux/chrysaki.conf"
    run ln -sf "$CHRYSAKI/help.sh"                  "$HOME/.config/tmux/help.sh"
    for s in "$CHRYSAKI"/scripts/*.sh; do
        run ln -sf "$s" "$HOME/.config/tmux/scripts/$(basename "$s")"
    done
    success "Chrysaki tmux symlinks created"
else
    warn "Chrysaki tmux port not found -- tmux config not linked"
fi

# ─── 8. Default shell ─────────────────────────────────────────────────────────
# Use usermod instead of chsh — chsh requires interactive password entry
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    info "Setting zsh as default shell..."
    run sudo usermod -s "$(which zsh)" "$USER"
else
    success "zsh already default shell, skipping"
fi

# ─── 8b. zinit: clone and pre-download all plugins ───────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    info "Cloning zinit..."
    run mkdir -p "$(dirname "$ZINIT_HOME")"
    run git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
    success "zinit already present, skipping clone"
fi

info "Pre-downloading zinit plugins and snippets..."
# Source zinit and declare all plugins/snippets so they get downloaded now.
# TERM=dumb + POWERLEVEL9K_INSTANT_PROMPT=off suppresses p10k output.
run env TERM=dumb POWERLEVEL9K_INSTANT_PROMPT=off zsh -c "
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

# ─── 9. SDDM login screen (Night Glass theme) ────────────────────────────────
# SDDM is the only password prompt. Hyprland does not start hyprlock at login.
info "Configuring SDDM..."
try sudo systemctl disable lightdm gdm
run sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
run sudo cp -r "$DOTS_DIR/system/usr/share/sddm/themes/night-glass" /usr/share/sddm/themes/
run sudo mkdir -p /etc/sddm.conf.d
run sudo cp "$DOTS_DIR/system/etc/sddm.conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
run sudo systemctl enable sddm
echo "[ok] SDDM enabled with the Night Glass theme"

# ─── 10. PostgreSQL ───────────────────────────────────────────────────────────
if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    info "Initialising PostgreSQL data directory..."
    run sudo -u postgres initdb --locale=en_US.UTF-8 -D /var/lib/postgres/data
else
    success "PostgreSQL already initialised, skipping"
fi
run sudo systemctl enable --now postgresql

# ─── 11. Font cache ───────────────────────────────────────────────────────────
info "Refreshing font cache..."
run sh -c 'fc-cache -fv > /dev/null'

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    success "Dry run complete. Nothing was changed."
else
    success "Bootstrap complete. Reboot to start Hyprland."
fi
echo ""
echo "  Next steps:"
echo "    1. Reboot  (required: docker group, SDDM, kernel modules)"
echo "    2. Connect Tailscale:     sudo tailscale up"
echo "    3. Set wallpaper:         ~/.config/hypr/scripts/wallpaper.sh"
echo "    4. Set up GitHub:         ~/dots/git/gh-setup.sh"
echo "    5. Optional CLI tools:    bash ~/dots/tools.sh"
