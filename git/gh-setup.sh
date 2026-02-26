#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# gh-setup.sh
# Sets up two GitHub accounts (personal + work) with:
#   - gh CLI authentication for both
#   - SSH keys for each, uploaded to GitHub
#   - ~/.ssh/config with host aliases
#
# Git identity per directory is handled by ~/.gitconfig includeIf rules:
#   ~/dev/              → personal (kiriketsuki)
#   ~/workdev/          → personal (default)
#   ~/workdev/Aurrigo/  → work (Jovian-Aurrigo)
# ─────────────────────────────────────────────────────────────────────────────
#
# ABOUT SSH KEYS
# ─────────────────────────────────────────────────────────────────────────────
# SSH keys come in pairs: a private key (kept secret, never shared) and a
# public key (safe to share — uploaded to GitHub). Git uses them instead of
# passwords when pushing/pulling over SSH.
#
# This script expects two key pairs:
#   ~/.ssh/id_personal   (private)  /  ~/.ssh/id_personal.pub   (public)
#   ~/.ssh/id_work       (private)  /  ~/.ssh/id_work.pub       (public)
#
# HOW TO CHECK IF YOU ALREADY HAVE KEYS
# ─────────────────────────────────────────────────────────────────────────────
#   ls -la ~/.ssh/
#
# You're looking for files named id_personal and id_work (no extension =
# private key, .pub = public key). If they exist, this script will skip
# generating new ones and use what's there.
#
# HOW TO GET YOUR KEYS FROM GITHUB (if you set them up on another machine)
# ─────────────────────────────────────────────────────────────────────────────
# Public keys can be listed in your GitHub account:
#   gh ssh-key list                        (requires gh auth login first)
#   # or visit: https://github.com/settings/keys
#
# However, GitHub only stores public keys — private keys never leave the
# machine they were generated on. To reuse keys from another machine:
#   1. Copy ~/.ssh/id_personal and ~/.ssh/id_personal.pub from the old machine
#   2. Place them at the same paths on this machine
#   3. Set correct permissions: chmod 600 ~/.ssh/id_personal
#   4. Then run this script — it will detect them and skip generation
#
# If you don't have access to the old machine, generate fresh keys (this
# script will do that automatically) and upload the new public keys to GitHub.
# Old keys on GitHub can be revoked at https://github.com/settings/keys
# ─────────────────────────────────────────────────────────────────────────────

PERSONAL_USER="kiriketsuki"
PERSONAL_EMAIL="kiriketsuki@gmail.com"
WORK_USER="Jovian-Aurrigo"
WORK_EMAIL="jlim@aurrigo.com"

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
step()    { echo ""; echo "── $* ──────────────────────────────────────────"; }

if ! command -v gh &>/dev/null; then
    echo "[error] gh CLI not found. Install it with: yay -S github-cli"
    exit 1
fi

# ─── 1. Authenticate both accounts ───────────────────────────────────────────
# Uses HTTPS for gh auth so gh doesn't generate its own SSH keys.
# SSH for git operations is handled separately below via ~/.ssh/config.

step "Step 1: Authenticate personal account ($PERSONAL_USER)"
if gh auth status 2>&1 | grep -q "Logged in to github.com account $PERSONAL_USER\|Logged in to github.com account ${PERSONAL_USER,,}"; then
    success "$PERSONAL_USER already authenticated, skipping"
else
    info "Follow the prompts to log in as $PERSONAL_USER"
    gh auth login --hostname github.com --git-protocol https
fi

step "Step 2: Authenticate work account ($WORK_USER)"
if gh auth status 2>&1 | grep -qi "Logged in to github.com account $WORK_USER"; then
    success "$WORK_USER already authenticated, skipping"
else
    info "Follow the prompts to log in as $WORK_USER"
    gh auth login --hostname github.com --git-protocol https
fi

# ─── 2. Generate SSH keys ─────────────────────────────────────────────────────
step "Step 3: SSH keys"

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_personal ]; then
    info "Generating personal SSH key..."
    ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f ~/.ssh/id_personal -N ""
else
    success "Personal SSH key already exists, skipping"
fi

if [ ! -f ~/.ssh/id_work ]; then
    info "Generating work SSH key..."
    ssh-keygen -t ed25519 -C "$WORK_EMAIL" -f ~/.ssh/id_work -N ""
else
    success "Work SSH key already exists, skipping"
fi

# ─── 3. Upload keys to GitHub ─────────────────────────────────────────────────
step "Step 4: Upload SSH keys to GitHub"

HOSTNAME="$(cat /etc/hostname 2>/dev/null || uname -n)"

gh auth switch --user "$PERSONAL_USER"
info "Uploading personal key as $PERSONAL_USER..."
gh ssh-key add ~/.ssh/id_personal.pub --title "$HOSTNAME-personal" 2>/dev/null \
    && success "Personal key uploaded" \
    || info "Personal key may already exist on GitHub, continuing"

gh auth switch --user "$WORK_USER"
info "Uploading work key as $WORK_USER..."
gh ssh-key add ~/.ssh/id_work.pub --title "$HOSTNAME-work" 2>/dev/null \
    && success "Work key uploaded" \
    || info "Work key may already exist on GitHub, continuing"

# Switch back to personal as the default active account
gh auth switch --user "$PERSONAL_USER"

# ─── 4. Write SSH config ──────────────────────────────────────────────────────
step "Step 5: Writing ~/.ssh/config"

SSH_CONFIG="$HOME/.ssh/config"
MARKER="# BEGIN dots gh-setup"

if grep -q "$MARKER" "$SSH_CONFIG" 2>/dev/null; then
    success "SSH config already configured, skipping"
else
    cat >> "$SSH_CONFIG" << EOF

$MARKER
# Personal GitHub account ($PERSONAL_USER)
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    AddKeysToAgent yes

# Work GitHub account ($WORK_USER)
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    AddKeysToAgent yes

# Default github.com → personal
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    AddKeysToAgent yes
# END dots gh-setup
EOF
    chmod 600 "$SSH_CONFIG"
    success "SSH config written"
fi

# ─── 5. Verify ────────────────────────────────────────────────────────────────
step "Verification"

info "Testing personal SSH connection..."
ssh -T -o StrictHostKeyChecking=no git@github.com-personal 2>&1 | grep -o "Hi [^!]*" || true

info "Testing work SSH connection..."
ssh -T -o StrictHostKeyChecking=no git@github.com-work 2>&1 | grep -o "Hi [^!]*" || true

echo ""
success "GitHub setup complete."
echo ""
echo "  Active gh accounts:"
gh auth status 2>&1 | grep -E "Logged in|Active account" || true
echo ""
echo "  Git identity is applied per directory:"
echo "    ~/dev/             → $PERSONAL_USER ($PERSONAL_EMAIL)"
echo "    ~/workdev/         → $PERSONAL_USER ($PERSONAL_EMAIL) [default]"
echo "    ~/workdev/Aurrigo/ → $WORK_USER ($WORK_EMAIL)"
echo ""
echo "  When cloning work repos, use the work SSH host:"
echo "    git clone git@github.com-work:Aurrigo/repo.git ~/workdev/Aurrigo/repo"
echo ""
echo "  For personal repos:"
echo "    git clone git@github.com:kiriketsuki/repo.git ~/dev/repo"
