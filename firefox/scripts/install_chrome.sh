#!/usr/bin/env bash
# Links the Chrysaki userChrome.css into every Firefox profile and turns on
# the pref that makes Firefox load it. Firefox reads both at its next start.
set -euo pipefail

FF_DIR="$HOME/.mozilla/firefox"
SRC="$(cd "$(dirname "$0")/.." && pwd)/chrome/userChrome.css"
PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
# Chrysaki is dark. A light built-in theme under it makes tab titles and the
# address bar popup unreadable, so every profile uses the dark built-in theme.
# 0 means dark for the toolbar and content theme prefs.
DARK_PREFS=(
    'user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");'
    'user_pref("browser.theme.toolbar-theme", 0);'
    'user_pref("browser.theme.content-theme", 0);'
)

[[ -f "$SRC" ]] || { echo "Error: $SRC not found. Run update_colors.py first." >&2; exit 1; }

for profile in "$FF_DIR"/*/; do
    [[ -f "$profile/prefs.js" ]] || continue
    mkdir -p "$profile/chrome"
    target="$profile/chrome/userChrome.css"
    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "Skip: $target is a real file. Move it away to use Chrysaki." >&2
        continue
    fi
    ln -sfn "$SRC" "$target"
    for p in "$PREF" "${DARK_PREFS[@]}"; do
        grep -qxF "$p" "$profile/user.js" 2>/dev/null || echo "$p" >> "$profile/user.js"
    done
    echo "Linked: $profile"
done
