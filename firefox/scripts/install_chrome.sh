#!/usr/bin/env bash
# Links the Chrysaki userChrome.css into every Firefox profile and turns on
# the pref that makes Firefox load it. Firefox reads both at its next start.
set -euo pipefail

FF_DIR="$HOME/.mozilla/firefox"
SRC="$(cd "$(dirname "$0")/.." && pwd)/chrome/userChrome.css"
PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

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
    grep -qxF "$PREF" "$profile/user.js" 2>/dev/null || echo "$PREF" >> "$profile/user.js"
    echo "Linked: $profile"
done
