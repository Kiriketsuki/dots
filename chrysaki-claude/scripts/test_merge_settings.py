import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parent / "merge_settings.py"
SPEC = importlib.util.spec_from_file_location("merge_settings", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

MODS = "/home/k/.local/share/claude-code-mods"
MANAGED = MODULE.load_managed(json.dumps({
    "mods": ["chrysaki-statusline", "git-pane"],
    "enabledPlugins": {"a@m": True, "b@m": False},
    "pluginConfigs": {"chrysaki-statusline": {"options": {"caption": "Tetsuhiro Dev"}}},
}))


class MergeSettingsTests(unittest.TestCase):
    def test_keeps_entries_it_does_not_manage(self):
        before = {
            "env": {"OTHER": "1", "CLAUDE_CODE_PLUGIN_DIRS": f"{MODS}/clodeks:{MODS}/git-pane"},
            "enabledPlugins": {"c@m": True, "a@m": False},
            "pluginConfigs": {"chrysaki-statusline": {"options": {"barStyle": "smooth"}}, "x": {"options": {"y": "z"}}},
            "outputStyle": "Terse",
        }
        after = MODULE.merged(before, MANAGED, MODS)
        self.assertEqual(after["env"]["OTHER"], "1")
        self.assertEqual(after["env"]["CLAUDE_CODE_PLUGIN_DIRS"], f"{MODS}/clodeks:{MODS}/git-pane:{MODS}/chrysaki-statusline")
        self.assertEqual(after["enabledPlugins"], {"c@m": True, "a@m": True, "b@m": False})
        self.assertEqual(after["pluginConfigs"]["chrysaki-statusline"], {"options": {"barStyle": "smooth", "caption": "Tetsuhiro Dev"}})
        self.assertEqual(after["pluginConfigs"]["x"], {"options": {"y": "z"}})
        self.assertEqual(after["outputStyle"], "Terse")
        self.assertEqual(before["enabledPlugins"]["a@m"], False)

    def test_a_second_merge_changes_nothing(self):
        once = MODULE.merged({}, MANAGED, MODS)
        self.assertEqual(MODULE.changes(once, MODULE.merged(once, MANAGED, MODS)), [])

    def test_rejects_a_bad_mods_file(self):
        for text in ('[]', '{"mods": ["../x"]}', '{"enabledPlugins": {"a": "yes"}}', '{"pluginConfigs": {"a": 1}}'):
            with self.assertRaises(MODULE.ConfigError):
                MODULE.load_managed(text)

    def test_writes_through_a_symlink_and_keeps_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            real = Path(tmp, "real.json")
            real.write_text(json.dumps({"enabledPlugins": {}}, indent=2) + "\n")
            link = Path(tmp, "settings.json")
            link.symlink_to(real)
            mods = Path(tmp, "mods.json")
            mods.write_text(json.dumps({"enabledPlugins": {"a@m": True}}))
            self.assertEqual(MODULE.main([str(mods), str(link), MODS]), 0)
            self.assertTrue(link.is_symlink())
            self.assertEqual(json.loads(real.read_text())["enabledPlugins"], {"a@m": True})

    def test_a_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp, "settings.json")
            settings.write_text("{}\n")
            mods = Path(tmp, "mods.json")
            mods.write_text(json.dumps({"enabledPlugins": {"a@m": True}}))
            self.assertEqual(MODULE.main([str(mods), str(settings), MODS, "--dry-run"]), 0)
            self.assertEqual(settings.read_text(), "{}\n")


if __name__ == "__main__":
    unittest.main()
