#!/usr/bin/env python3
"""Merge the managed part of mods.json into a Claude Code settings.json.

The script sets each enabled plugin that mods.json names. It merges the
options of each mod in pluginConfigs. It adds each managed mod folder to
CLAUDE_CODE_PLUGIN_DIRS. Every entry that mods.json does not name stays,
for example the clodeKs mod folder.

Usage: merge_settings.py MODS_JSON SETTINGS_JSON MODS_DIR [--dry-run]
"""

import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

SEP = os.pathsep
MOD_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")


class ConfigError(Exception):
    pass


def load_managed(text):
    """Return mods.json as a dict, or raise ConfigError when a field has the wrong shape."""
    data = json.loads(text)
    if not isinstance(data, dict):
        raise ConfigError("mods.json must hold an object")
    mods = data.get("mods", [])
    if not isinstance(mods, list) or not all(isinstance(m, str) and MOD_NAME.match(m) for m in mods):
        raise ConfigError("mods must be a list of mod folder names")
    plugins = data.get("enabledPlugins", {})
    if not isinstance(plugins, dict) or not all(isinstance(v, bool) for v in plugins.values()):
        raise ConfigError("enabledPlugins must map plugin names to true or false")
    configs = data.get("pluginConfigs", {})
    if not isinstance(configs, dict) or not all(isinstance(v, dict) for v in configs.values()):
        raise ConfigError("pluginConfigs must map plugin names to objects")
    return {"mods": mods, "enabledPlugins": plugins, "pluginConfigs": configs}


def merge_config(old, new):
    """Merge one plugin config. The options merge key by key."""
    out = {**old, **new}
    if "options" in old or "options" in new:
        out["options"] = {**old.get("options", {}), **new.get("options", {})}
    return out


def merged(settings, managed, mods_dir):
    """Return a new settings dict with the managed entries merged in."""
    env = dict(settings.get("env", {}))
    dirs = [d for d in env.get("CLAUDE_CODE_PLUGIN_DIRS", "").split(SEP) if d]
    wanted = [f"{mods_dir.rstrip('/')}/{m}" for m in managed["mods"]]
    joined = SEP.join(dirs + [d for d in wanted if d not in dirs])
    if joined or "CLAUDE_CODE_PLUGIN_DIRS" in env:
        env["CLAUDE_CODE_PLUGIN_DIRS"] = joined
    plugins = {**settings.get("enabledPlugins", {}), **managed["enabledPlugins"]}
    configs = dict(settings.get("pluginConfigs", {}))
    for name, conf in managed["pluginConfigs"].items():
        configs[name] = merge_config(configs.get(name, {}), conf)
    return {**settings, "env": env, "enabledPlugins": plugins, "pluginConfigs": configs}


def changes(before, after):
    """Return one line for each top-level key that the merge changes."""
    lines = []
    for key in ("env", "enabledPlugins", "pluginConfigs"):
        old, new = before.get(key, {}), after.get(key, {})
        for name in new:
            if old.get(name) != new[name]:
                lines.append(f"{key}.{name}: {json.dumps(old.get(name))} -> {json.dumps(new[name])}")
    return lines


def write_json(path, data):
    """Replace the file that path leads to in one step. A symlink at path stays a symlink."""
    target = Path(os.path.realpath(path))
    fd, tmp = tempfile.mkstemp(dir=target.parent, prefix=f".{target.name}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(json.dumps(data, indent=2) + "\n")
        shutil.copymode(target, tmp)
        os.replace(tmp, target)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def main(argv):
    args = [a for a in argv if a != "--dry-run"]
    if len(args) != 3:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    mods_json, settings_json, mods_dir = args
    try:
        managed = load_managed(Path(mods_json).read_text(encoding="utf-8"))
        before = json.loads(Path(settings_json).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError, ConfigError) as e:
        print(f"merge_settings: cannot read the input: {e}", file=sys.stderr)
        return 1
    after = merged(before, managed, mods_dir)
    lines = changes(before, after)
    for line in lines:
        print(f"settings: {line}")
    if not lines:
        print("settings: no change")
    elif "--dry-run" not in argv:
        write_json(settings_json, after)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
