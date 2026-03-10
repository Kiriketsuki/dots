#!/bin/bash
# vsc-repatch.sh — Re-apply Chrysaki VSCode setup after a VSCode update.
#
# VSCode updates reset workbench.html to root ownership, breaking Custom CSS
# injection. Run this after any VSCode update, then re-run "Enable Custom CSS
# and JS" from the VSCode command palette.

set -e

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }

CHRYSAKI_VSC="$HOME/dev/obKidian/000-System/Themes/Chrysaki/vscode"
WORKBENCH_HTML="/opt/visual-studio-code/resources/app/out/vs/code/electron-browser/workbench/workbench.html"

# ── 1. Re-link extension ──────────────────────────────────────────────────────
if [ -d "$CHRYSAKI_VSC" ]; then
    info "Re-linking Chrysaki VSCode extension..."
    mkdir -p "$HOME/.vscode/extensions"
    rm -rf "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    ln -sf "$CHRYSAKI_VSC" "$HOME/.vscode/extensions/chrysaki-theme-2.0.0"
    success "Extension symlinked → $CHRYSAKI_VSC"
else
    warn "Chrysaki repo not found at $CHRYSAKI_VSC"
fi

# ── 2. Fix workbench.html ownership ──────────────────────────────────────────
if [ -f "$WORKBENCH_HTML" ]; then
    info "Fixing workbench.html ownership..."
    sudo chown "$USER" "$WORKBENCH_HTML"
    success "workbench.html owned by $USER"
else
    warn "workbench.html not found at $WORKBENCH_HTML"
fi

echo ""
success "Done. Now run 'Enable Custom CSS and JS' in the VSCode command palette."
