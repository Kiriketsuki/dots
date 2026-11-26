#!/usr/bin/env python3
"""Write the -symbolic copies of the toolbar icons into gtk/icons/symbolic.

GTK draws a -symbolic icon with a forced fill on every shape. A stroked
line then disappears, so each copy needs its strokes turned into filled
outlines. picosvg does that. It runs through uvx, so this is a dev-time
step. Run it after an iconsmith build that changes a toolbar icon:

    python gtk/scripts/make_symbolic.py

The output is committed. make_icon_theme.py installs it with no extra tools.
"""
import pathlib
import subprocess
import sys

ICONS = pathlib.Path(__file__).resolve().parent.parent / "icons"
BUILD = ICONS / "build"
OUT = ICONS / "symbolic"
# Thunar asks for these names with the -symbolic suffix.
NAMES = (
    "go-previous", "go-next", "go-up", "go-home", "system-search", "open-menu",
    "view-as-icons", "view-as-detailed-list", "view-as-compact-list", "media-eject",
)


def outline(source: pathlib.Path) -> str:
    """Return the SVG with every stroke turned into a filled outline."""
    result = subprocess.run(
        ["uvx", "picosvg", str(source)], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        sys.exit(f"picosvg failed on {source.name}: {result.stderr.strip()}")
    return result.stdout


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for name in NAMES:
        source = BUILD / f"{name}.svg"
        if not source.is_file():
            sys.exit(f"{source} is missing. Run the iconsmith build first.")
        (OUT / f"{name}-symbolic.svg").write_text(outline(source))
    print(f"Wrote {len(NAMES)} symbolic icons to {OUT}.")


if __name__ == "__main__":
    main()
