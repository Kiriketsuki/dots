#!/usr/bin/env bash
# Fuzzy-pick a Firefox user profile and open it.
#
# Usage: firefox_profiles.sh [--rofi | --list] [query]
#   In a terminal, fzf picks the profile. Elsewhere, or with --rofi, rofi does.
#   A query that matches one profile opens it with no prompt.
#   --list prints the profile names and paths and opens nothing.
#
# Firefox keeps the user profiles of the profile switcher in a profile group
# database, not in profiles.ini. profiles.ini names the group by StoreID.

set -euo pipefail

FF_DIR="$HOME/.mozilla/firefox"
ROFI_THEME="$HOME/.config/rofi/jovian/theme.rasi"

use_rofi=0
list_only=0
case "${1:-}" in
--rofi) use_rofi=1; shift ;;
--list) list_only=1; shift ;;
esac
query="${*:-}"
[[ -t 0 && -t 1 ]] || use_rofi=1

die() {
	if [[ $use_rofi -eq 1 ]] && command -v notify-send >/dev/null; then
		notify-send -a Firefox "Firefox profiles" "$1"
	fi
	echo "firefox_profiles: $1" >&2
	exit 1
}

store_id="$(sed -n 's/^StoreID=//p' "$FF_DIR/profiles.ini" | head -n 1)"
[[ -n "$store_id" ]] || die "profiles.ini has no StoreID. Create a profile in the Firefox profile switcher first."
db="$FF_DIR/Profile Groups/$store_id.sqlite"
[[ -f "$db" ]] || die "The profile group database $db does not exist."

# A running Firefox holds the database open, and recent rows can sit in the
# WAL file. A copy of all three files reads every row and never takes a lock.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for f in "$db" "$db-wal" "$db-shm"; do
	if [[ -f "$f" ]]; then
		command cp "$f" "$tmp/"
	fi
done

# One "name<TAB>path" line per profile, in the switcher's order.
rows="$(sqlite3 -separator $'\t' "$tmp/$store_id.sqlite" 'SELECT name, path FROM Profiles ORDER BY id;')"
[[ -n "$rows" ]] || die "The profile group holds no profiles."
if [[ $list_only -eq 1 ]]; then
	printf '%s\n' "$rows"
	exit 0
fi

pick_fzf() {
	cut -f1 <<<"$rows" | fzf --query="$query" --select-1 --exit-0 --prompt='firefox  ' --height=40% --reverse
}

pick_rofi() {
	cut -f1 <<<"$rows" | rofi -dmenu -i -matching fuzzy -p ' firefox' -filter "$query" -theme "$ROFI_THEME"
}

if [[ $use_rofi -eq 1 ]]; then
	name="$(pick_rofi || true)"
else
	name="$(pick_fzf || true)"
fi
[[ -n "$name" ]] || exit 0

path="$(awk -F'\t' -v n="$name" '$1 == n { print $2; exit }' <<<"$rows")"
[[ -n "$path" ]] || die "No profile is named $name."
[[ "$path" == /* ]] || path="$FF_DIR/$path"
[[ -d "$path" ]] || die "The folder of profile $name does not exist: $path"

# Firefox hands the call to the window that already runs this profile, if
# one does. setsid keeps the browser alive after the terminal closes.
setsid -f firefox --profile "$path" >/dev/null 2>&1
