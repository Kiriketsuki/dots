import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

DOTS = Path(__file__).resolve().parents[2]
SCRIPT = DOTS / "theme/scripts/generate_theme_css.py"
SPEC = importlib.util.spec_from_file_location("generate_theme_css", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GenerateThemeCssTests(unittest.TestCase):
    def test_pinned_core_preserves_golden_tokens(self):
        core = MODULE.parse_core_json(DOTS / "chrysaki/core/chrysaki.json")
        golden = json.loads((DOTS / "chrysaki/docs/migration/golden-tokens.json").read_text())["tokens"]
        self.assertEqual({name: core[name] for name in golden}, golden)

    def test_legacy_scss_rollback_matches_core_for_existing_tokens(self):
        raw = MODULE.parse_scss(DOTS / "chrysaki/ags/.config/ags/styles/_palette.scss")
        legacy = MODULE.resolve_scss(raw)
        core = MODULE.parse_core_json(DOTS / "chrysaki/core/chrysaki.json")
        self.assertEqual(
            {name: value.lower() for name, value in legacy.items()},
            {name: core[name].lower() for name in legacy},
        )

    def test_generated_css_contains_every_core_token(self):
        core = MODULE.parse_core_json(DOTS / "chrysaki/core/chrysaki.json")
        css = MODULE.generate_theme_css(core)
        for name, value in core.items():
            self.assertIn(f"@define-color chrysaki-{name} {value};", css)

    def test_invalid_resolved_token_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "invalid.json"
            source.write_text('{"tokens":{"bad":"red"}}')
            with self.assertRaisesRegex(ValueError, "invalid resolved tokens: bad"):
                MODULE.parse_core_json(source)


if __name__ == "__main__":
    unittest.main()
