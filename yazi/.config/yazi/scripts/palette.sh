#!/usr/bin/env bash
# palette.sh -- Chrysaki fzf command palette for yazi
# Bound to: ? key in yazi
# Protocol: LABEL<TAB>ya emit COMMAND -- fzf shows only the label column.

export TERM="${TERM:-xterm-256color}"

if ! command -v fzf &>/dev/null; then
  echo "palette: fzf not found -- pacman -S fzf"
  sleep 1
  exit 1
fi

ENTRIES=$(cat <<'EOF'
 Navigation
Go to home directory	cd ~
Go to downloads	cd ~/Downloads
Go to documents	cd ~/Documents
Go to dev folder	cd ~/dev
Go to dotfiles	cd ~/dots
Go to vault	cd ~/dev/obKidian
Go to parent directory	leave
Enter directory	enter
Go back (previous directory)	back
Go forward	forward

 Sort
Sort by name (natural)	sort natural --dir-first
Sort by name (reverse)	sort natural --reverse --dir-first
Sort by modified time	sort mtime --dir-first
Sort by modified (oldest first)	sort mtime --reverse --dir-first
Sort by size (largest first)	sort size --dir-first
Sort by size (smallest first)	sort size --reverse --dir-first
Sort by extension	sort ext --dir-first

 View
Toggle hidden files	hidden toggle
Refresh directory	reload

 Selection
Select all files	select_all --state=true
Deselect all	select_all --state=false
Toggle selection on hovered	select --state=none

 File Operations
Open file	open
Open with picker	open --interactive
Rename file	rename
Create new file	create
Copy selected files	yank
Cut selected files	yank --cut
Paste files	paste
Paste (overwrite)	paste --force
Delete to trash	remove
Delete permanently	remove --permanently

 Copy Info
Copy file path	copy path
Copy directory path	copy dirname
Copy filename	copy filename
Copy filename without ext	copy name_without_ext

 Search
Search in current dir	search fd
Search by content (rg)	search rg
Cancel search	search none
Filter files	filter

 Tabs
New tab	tab_create --current
Close current tab	tab_close 0
Switch to next tab	tab_switch 1 --relative
Switch to previous tab	tab_switch -1 --relative

 Help
Show keybindings	help
EOF
)

tmp_entries=$(mktemp /tmp/yazi-palette-XXXXXX)
printf '%s\n' "$ENTRIES" > "$tmp_entries"

SELECTED=$(fzf \
    --ansi \
    --delimiter=$'\t' \
    --with-nth=1 \
    --layout=reverse \
    --border=sharp \
    --height=100% \
    --padding=0,1 \
    --prompt=" ❯  " \
    --pointer="▸" \
    --marker="  " \
    --header=" ↑↓ navigate  ↵ execute  esc cancel" \
    --header-first \
    --color="dark" \
    --color="bg:#0f1117,bg+:#252836" \
    --color="fg:#a0a4b8,fg+:#e0e2ea" \
    --color="hl:#1a8a6a,hl+:#1a8a6a" \
    --color="border:#363a4f,label:#1a8a6a" \
    --color="prompt:#FBB13C,pointer:#FBB13C" \
    --color="header:#6a6e82,query:#e0e2ea,gutter:#0f1117" \
    --no-sort \
    --bind "esc:abort" \
    < "$tmp_entries")

rm -f "$tmp_entries"

[ -z "$SELECTED" ] && exit 0

COMMAND=$(printf '%s' "$SELECTED" | cut -f2-)
[ -z "$COMMAND" ] && exit 0

# Section headers start with  — skip them
case "$COMMAND" in
    " "*) exit 0 ;;
esac

# ya emit takes NAME [ARGS]... as separate words
# shellcheck disable=SC2086
ya emit $COMMAND
