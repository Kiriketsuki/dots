#!/usr/bin/env python3
"""Build the Chrysaki icon theme in ~/.local/share/icons/Chrysaki.

The theme inherits Papirus-Dark. It replaces only the folder icons, with links
to one Papirus folder colour. Papirus itself stays untouched, so a pacman
update never conflicts with it. Run this again after a Papirus update or to
change the colour:

    python gtk/scripts/make_icon_theme.py [colour]

The colour is a Papirus folder colour such as teal, cyan, violet or indigo.
"""
import pathlib
import re
import shutil
import sys

PAPIRUS = pathlib.Path("/usr/share/icons/Papirus")
OUT = pathlib.Path.home() / ".local/share/icons/Chrysaki"
DEFAULT_COLOUR = "teal"
# Papirus names a coloured icon by putting the colour after the first word:
# folder-teal-music.svg replaces folder-music.svg, user-teal-home.svg replaces
# user-home.svg. These are the first words that take a colour.
PREFIXES = ("folder", "user", "network-workgroup")


def plain_name(name: str, colour: str) -> str | None:
    """Return the plain icon name for a coloured one, or None."""
    for prefix in PREFIXES:
        tag = f"{prefix}-{colour}"
        if name == f"{tag}.svg":
            return f"{prefix}.svg"
        if name.startswith(f"{tag}-"):
            return f"{prefix}-{name[len(tag) + 1:]}"
    return None


def size_of(dirname: str) -> tuple[int, int]:
    match = re.fullmatch(r"(\d+)x\d+(@2x)?", dirname)
    if not match:
        raise ValueError(f"Unexpected Papirus folder name: {dirname}")
    return int(match.group(1)), 2 if match.group(2) else 1


def main() -> None:
    colour = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_COLOUR
    if not PAPIRUS.is_dir():
        sys.exit("Papirus is not installed. Install papirus-icon-theme first.")
    if OUT.exists():
        shutil.rmtree(OUT)

    dirs = []
    links = 0
    for places in sorted(PAPIRUS.glob("*/places")):
        size_dir = places.parent.name
        size, scale = size_of(size_dir)
        target_dir = OUT / size_dir / "places"
        target_dir.mkdir(parents=True)
        for icon in places.iterdir():
            plain = plain_name(icon.name, colour)
            if plain:
                (target_dir / plain).symlink_to(icon.resolve())
                links += 1
        dirs.append((f"{size_dir}/places", size, scale))

    if links == 0:
        sys.exit(f"Papirus has no folder icons in the colour {colour}.")

    lines = [
        "[Icon Theme]",
        "Name=Chrysaki",
        f"Comment=Papirus-Dark with {colour} folders. Made by dots/gtk/scripts/make_icon_theme.py.",
        "Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor",
        "Directories=" + ",".join(d for d, _, _ in dirs),
        "",
    ]
    for name, size, scale in dirs:
        lines += [f"[{name}]", "Context=Places", f"Size={size}", f"Scale={scale}", "Type=Fixed", ""]
    (OUT / "index.theme").write_text("\n".join(lines))
    print(f"Built {OUT} with {links} {colour} folder links.")


if __name__ == "__main__":
    main()
