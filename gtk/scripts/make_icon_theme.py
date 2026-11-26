#!/usr/bin/env python3
"""Build the Chrysaki icon theme in ~/.local/share/icons/Chrysaki.

The theme inherits Papirus-Dark. It replaces only the folder icons, with links
to one Papirus folder colour. Papirus itself stays untouched, so a pacman
update never conflicts with it.

It also installs the custom iconsmith set from gtk/icons/build. Each icon gets
the gem colour of its kind in place of currentColor. A custom icon replaces the
Papirus link of the same name. Run this again after a Papirus update or to
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

BUILD = pathlib.Path(__file__).resolve().parent.parent / "icons" / "build"
# Gem colours from quickshell/.config/quickshell/Theme.qml.
TEAL_LT = "#6fd3d6"
MUTED = "#b3a998"
# Icon name: (context folder, colour).
CUSTOM = {
    "folder": ("places", TEAL_LT),
    "folder-open": ("places", TEAL_LT),
    "folder-documents": ("places", TEAL_LT),
    "folder-download": ("places", TEAL_LT),
    "folder-music": ("places", TEAL_LT),
    "folder-pictures": ("places", TEAL_LT),
    "folder-videos": ("places", TEAL_LT),
    "folder-projects": ("places", TEAL_LT),
    "user-home": ("places", TEAL_LT),
    "user-desktop": ("places", TEAL_LT),
    "network-workgroup": ("places", TEAL_LT),
    "document-open-recent": ("places", TEAL_LT),
    "user-trash": ("places", MUTED),
    "user-trash-full": ("places", MUTED),
    "computer": ("devices", MUTED),
    "drive-harddisk": ("devices", MUTED),
    "drive-removable-media": ("devices", MUTED),
    "text-x-generic": ("mimetypes", "#e8e2d6"),
    "image-x-generic": ("mimetypes", "#d0609f"),
    "audio-x-generic": ("mimetypes", "#b4bf3a"),
    "video-x-generic": ("mimetypes", "#e08a3c"),
    "package-x-generic": ("mimetypes", "#c9a27a"),
    "text-x-script": ("mimetypes", "#a383e3"),
    "x-office-spreadsheet": ("mimetypes", "#2fb38a"),
    "application-pdf": ("mimetypes", "#f29aa2"),
    # Toolbar actions take the muted text colour of the Thunar toolbar.
    "go-previous": ("actions", MUTED),
    "go-next": ("actions", MUTED),
    "go-up": ("actions", MUTED),
    "go-home": ("actions", MUTED),
    "system-search": ("actions", MUTED),
    "open-menu": ("actions", MUTED),
    "view-as-icons": ("actions", MUTED),
    "view-as-detailed-list": ("actions", MUTED),
    "view-as-compact-list": ("actions", MUTED),
    "media-eject": ("actions", MUTED),
}
# Outlined -symbolic copies of the toolbar icons. make_symbolic.py writes them.
SYMBOLIC = BUILD.parent / "symbolic"
# Extra names that show the same drawing. Alias: source icon.
ALIASES = {
    "inode-directory": "folder",
    "x-office-document": "text-x-generic",
    "application-x-executable": "text-x-script",
    "application-x-shellscript": "text-x-script",
}


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


# Thunar shows the most specific mime icon that any theme has, for example
# audio-mpeg from Papirus before audio-x-generic from Chrysaki. So each
# Papirus mime name links to the custom icon of its family. The first rule
# that matches wins. A name that no rule matches keeps its Papirus icon.
MIME_RULES = (
    (("pdf",), "application-pdf"),
    # Disk images come before "image", so an ISO does not show a photo.
    (("disk", "diskimage", "iso", "iso9660", "appimage", "disc", "cd", "media"), "package-x-generic"),
    (("compressed", "archive", "zip", "tar", "rar", "7z", "xz", "bzip", "gzip",
      "zstd", "lzma", "rpm", "deb", "package", "cpio"), "package-x-generic"),
    (("spreadsheet", "csv", "excel", "calc", "sheet"), "x-office-spreadsheet"),
    (("script", "python", "shell", "javascript", "typescript", "rust", "go",
      "csrc", "chdr", "c++", "java", "ruby", "perl", "php", "lua", "makefile",
      "json", "yaml", "toml", "xml", "sql", "css", "html", "executable"), "text-x-script"),
    (("audio",), "audio-x-generic"),
    (("video",), "video-x-generic"),
    (("image",), "image-x-generic"),
    (("text", "document", "word", "writer", "rtf", "markdown"), "text-x-generic"),
)


def mime_family(name: str) -> str | None:
    """Return the custom icon for a Papirus mime icon name, or None."""
    words = set(name.replace("+", "-").replace(".", "-").split("-"))
    for hints, target in MIME_RULES:
        if any(h in words or (len(h) > 3 and h in name) for h in hints):
            return target
    return None


def link_mime_families() -> int:
    """Link every Papirus mime name to its family icon. Return the count."""
    target_dir = OUT / "scalable" / "mimetypes"
    count = 0
    for icon in sorted((PAPIRUS / "64x64" / "mimetypes").glob("*.svg")):
        name = icon.stem
        target = mime_family(name)
        link = target_dir / icon.name
        if target is None or name in CUSTOM or link.exists():
            continue
        link.symlink_to(f"{target}.svg")
        count += 1
    return count


def install_custom() -> list[tuple[str, int, int, str]]:
    """Write the coloured iconsmith icons. Return their index.theme folders."""
    if not BUILD.is_dir():
        sys.exit(f"{BUILD} is missing. Run the iconsmith build first.")
    contexts = set()
    for name, (context, colour) in CUSTOM.items():
        source = BUILD / f"{name}.svg"
        if not source.is_file():
            sys.exit(f"{source} is missing. Run the iconsmith build first.")
        target_dir = OUT / "scalable" / context
        target_dir.mkdir(parents=True, exist_ok=True)
        svg = source.read_text().replace("currentColor", colour)
        (target_dir / f"{name}.svg").write_text(svg)
        contexts.add(context)
    for alias, name in ALIASES.items():
        context = CUSTOM[name][0]
        (OUT / "scalable" / context / f"{alias}.svg").symlink_to(f"{name}.svg")
    # GTK sets the colour of a -symbolic icon itself, so these go in as they are.
    for icon in sorted(SYMBOLIC.glob("*-symbolic.svg")):
        (OUT / "scalable" / "actions" / icon.name).write_text(icon.read_text())
    print(f"Linked {link_mime_families()} Papirus mime names to the custom icons.")
    return [(f"scalable/{c}", 24, 1, c.capitalize()) for c in sorted(contexts)]


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
            # A custom icon replaces the Papirus icon of the same name.
            if plain and plain[:-4] not in CUSTOM and plain[:-4] not in ALIASES:
                (target_dir / plain).symlink_to(icon.resolve())
                links += 1
        dirs.append((f"{size_dir}/places", size, scale, "Places"))

    if links == 0:
        sys.exit(f"Papirus has no folder icons in the colour {colour}.")
    # The custom folders come first, so GTK searches them before the links.
    dirs = install_custom() + dirs

    lines = [
        "[Icon Theme]",
        "Name=Chrysaki",
        f"Comment=Papirus-Dark with {colour} folders. Made by dots/gtk/scripts/make_icon_theme.py.",
        "Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor",
        "Directories=" + ",".join(d for d, _, _, _ in dirs),
        "",
    ]
    for name, size, scale, context in dirs:
        lines += [f"[{name}]", f"Context={context}", f"Size={size}", f"Scale={scale}"]
        if name.startswith("scalable/"):
            lines += ["Type=Scalable", "MinSize=8", "MaxSize=512", ""]
        else:
            lines += ["Type=Fixed", ""]
    (OUT / "index.theme").write_text("\n".join(lines))
    print(f"Built {OUT} with {len(CUSTOM)} custom icons and {links} {colour} folder links.")


if __name__ == "__main__":
    main()
