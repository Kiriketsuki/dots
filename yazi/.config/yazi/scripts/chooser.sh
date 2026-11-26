#!/bin/sh
# Runs yazi as the ttypicker file chooser.
# Usage: chooser.sh OUT_PATH [IN_PATH]

out="$1"
shift

yazi --chooser-file="$out" "$@"
status=$?

# Yazi search results write "search://query:N:N//actual/path" instead of a
# clean path. ttypicker rejects a path that is not absolute, so strip the prefix.
if [ -f "$out" ]; then
    sed -i 's|^search://[^/]*/||' "$out"
fi

exit "$status"
