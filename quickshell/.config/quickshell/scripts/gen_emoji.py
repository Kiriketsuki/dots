#!/usr/bin/env python3
"""Write data/emoji.tsv for the launcher from the unicode-emoji package.

Each output line is: emoji, a tab, then the name and group words. The launcher
searches the second field. Run this again after a unicode-emoji update.
"""
import pathlib
import re

SOURCE = pathlib.Path("/usr/share/unicode/emoji/emoji-test.txt")
OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "emoji.tsv"
LINE = re.compile(r"^[0-9A-F ]+;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$")


def main() -> None:
    group = ""
    rows = []
    for raw in SOURCE.read_text(encoding="utf-8").splitlines():
        if raw.startswith("# subgroup:"):
            group = raw.split(":", 1)[1].strip().replace("-", " ")
            continue
        match = LINE.match(raw)
        if match:
            char, name = match.groups()
            rows.append(f"{char}\t{name} ({group})")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"Wrote {len(rows)} emoji to {OUT}")


if __name__ == "__main__":
    main()
