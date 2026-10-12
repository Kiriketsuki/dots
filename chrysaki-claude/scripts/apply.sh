#!/usr/bin/env bash
# Apply my Claude Code mod setup on this machine.
#
# Usage: apply.sh [--dry-run]
#   --dry-run prints each change and makes none.
#
# 1. Link ~/.config/chrysaki/claude.json to the personal config in the
#    private vault. The dots repo is public, so the file stays out of it.
# 2. Copy each mod in mods.json from the chrysaki-claude checkout into
#    ~/.local/share/claude-code-mods. Other entries there stay.
# 3. Merge the enabled plugins, mod options and mod folders of mods.json
#    into ~/.claude/settings.json. Entries that mods.json does not name stay.
#
# CHRYSAKI_CLAUDE_REPO, CHRYSAKI_CLAUDE_VAULT_CONFIG and CLAUDE_MODS_DIR
# override the default paths.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${CHRYSAKI_CLAUDE_REPO:-$HOME/dev/Personal/chrysaki-claude}"
VAULT_CONFIG="${CHRYSAKI_CLAUDE_VAULT_CONFIG:-$HOME/dev/obKidian/000-System/Agents/Claude/chrysaki/claude.json}"
MODS_DIR="${CLAUDE_MODS_DIR:-$HOME/.local/share/claude-code-mods}"
SETTINGS="$HOME/.claude/settings.json"
CONFIG_LINK="${XDG_CONFIG_HOME:-$HOME/.config}/chrysaki/claude.json"

dry_run=0
case "${1:-}" in
--dry-run) dry_run=1 ;;
"") ;;
*) echo "Usage: apply.sh [--dry-run]" >&2; exit 2 ;;
esac

die() {
	echo "apply: $1" >&2
	exit 1
}

run() {
	if [[ $dry_run -eq 1 ]]; then
		echo "would run: $*"
	else
		"$@"
	fi
}

link_config() {
	if [[ ! -f $VAULT_CONFIG ]]; then
		echo "apply: no personal config at $VAULT_CONFIG. Copy $REPO/mods/chrysaki-statusline/personal.example.json there and edit it." >&2
		return 0
	fi
	if [[ -L $CONFIG_LINK && $(readlink "$CONFIG_LINK") == "$VAULT_CONFIG" ]]; then
		echo "config: $CONFIG_LINK is linked"
		return 0
	fi
	if [[ -e $CONFIG_LINK && ! -L $CONFIG_LINK ]]; then
		die "$CONFIG_LINK is a real file. Move it to $VAULT_CONFIG, then run apply.sh again."
	fi
	run mkdir -p "$(dirname "$CONFIG_LINK")"
	run ln -sfn "$VAULT_CONFIG" "$CONFIG_LINK"
	[[ $dry_run -eq 1 ]] || echo "config: $CONFIG_LINK -> $VAULT_CONFIG"
}

copy_mods() {
	[[ -d $REPO/mods ]] || die "no chrysaki-claude checkout at $REPO"
	local branch commit
	branch="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
	commit="$(git -C "$REPO" rev-parse --short HEAD)"
	echo "mods: from $REPO at $branch ($commit)"
	[[ $branch == main ]] || echo "apply: warning: the checkout is on $branch, not main" >&2
	local mods
	mapfile -t mods < <(python3 -I -c 'import json, sys; print("\n".join(json.load(open(sys.argv[1]))["mods"]))' "$HERE/mods.json")
	local flags=(-a --delete --exclude .claude-plugin/types --exclude node_modules --exclude __pycache__)
	[[ $dry_run -eq 1 ]] && flags+=(--dry-run --itemize-changes)
	for mod in "${mods[@]}"; do
		[[ $mod =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "mods.json names a bad mod folder: $mod"
		[[ -d $REPO/mods/$mod ]] || die "$REPO/mods has no mod $mod"
		if [[ -L $MODS_DIR/$mod ]]; then
			echo "mods: $mod is a symlink in $MODS_DIR. Skipped."
			continue
		fi
		run mkdir -p "$MODS_DIR/$mod"
		rsync "${flags[@]}" "$REPO/mods/$mod/" "$MODS_DIR/$mod/"
		if [[ $dry_run -eq 1 ]]; then echo "mods: $mod would be copied"; else echo "mods: $mod copied"; fi
	done
}

merge_settings() {
	local flags=()
	[[ $dry_run -eq 1 ]] && flags+=(--dry-run)
	python3 -I "$HERE/merge_settings.py" "$HERE/mods.json" "$SETTINGS" "$MODS_DIR" "${flags[@]}"
}

link_config
copy_mods
merge_settings
