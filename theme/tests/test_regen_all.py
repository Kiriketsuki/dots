import contextlib
import importlib.util
import io
from pathlib import Path
import unittest

DOTS = Path(__file__).resolve().parents[2]
SCRIPT = DOTS / "theme/scripts/regen_all.py"
SPEC = importlib.util.spec_from_file_location("regen_all", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

DOCUMENTED_ORDER = ["bridge", "btop", "ghostty", "gtk", "hypr", "lazygit", "firefox"]


def no_snapshot(root, package):
    return {}


class RegenAllTests(unittest.TestCase):
    def test_full_run_follows_documented_order(self):
        names = [step.name for step in MODULE.build_steps()]
        self.assertEqual(names, DOCUMENTED_ORDER)

    def test_every_step_script_exists(self):
        for step in MODULE.build_steps():
            self.assertTrue((DOTS / step.script).is_file(), step.script)

    def test_only_parsing_keeps_documented_order(self):
        only = MODULE.parse_only("gtk, btop")
        self.assertEqual(only, ["gtk", "btop"])
        names = [step.name for step in MODULE.build_steps(only)]
        self.assertEqual(names, ["bridge", "btop", "gtk"])

    def test_only_rejects_unknown_name(self):
        with self.assertRaisesRegex(ValueError, "unknown step: nope"):
            MODULE.parse_only("btop,nope")

    def test_skip_bridge_drops_only_the_bridge(self):
        names = [step.name for step in MODULE.build_steps(skip_bridge=True)]
        self.assertEqual(names, DOCUMENTED_ORDER[1:])

    def test_run_stops_at_first_failure(self):
        calls = []

        def runner(step, root):
            calls.append(step.name)
            return 3 if step.name == "gtk" else 0

        with contextlib.redirect_stderr(io.StringIO()):
            results = MODULE.run_all(MODULE.build_steps(), DOTS, runner, no_snapshot)
        self.assertEqual(calls, ["bridge", "btop", "ghostty", "gtk"])
        self.assertEqual(results[-1][1], 3)

    def test_main_reports_failure_exit_code(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
            code = MODULE.main(
                ["--only", "btop"],
                runner=lambda step, root: 1 if step.name == "btop" else 0,
                snap=no_snapshot,
            )
        self.assertEqual(code, 1)
        self.assertIn("btop: failed (exit 1)", out.getvalue())

    def test_stow_is_printed_not_run_without_flag(self):
        states = {"before": True}

        def snap(root, package):
            # The first call per step is "before", the second is "after".
            states["before"] = not states["before"]
            return {} if not states["before"] else {"f": ("M ", "1")}

        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = MODULE.main(
                ["--only", "btop"], runner=lambda step, root: 0, snap=snap
            )
        self.assertEqual(code, 0)
        self.assertIn("would run: stow --restow", out.getvalue())
        self.assertNotIn("running: stow", out.getvalue())

    def test_stow_packages_lists_changed_successful_steps_once(self):
        steps = {step.name: step for step in MODULE.build_steps()}
        results = [
            (steps["bridge"], 0, ["theme/.config/theme/theme.css"]),
            (steps["btop"], 0, []),
            (steps["gtk"], 0, ["gtk/gtk-3.0/gtk.css", "gtk/gtk-4.0/gtk.css"]),
        ]
        self.assertEqual(MODULE.stow_packages(results), ["theme", "gtk"])

    def test_changed_paths_detects_new_and_edited_content(self):
        before = {"a": ("M ", "1"), "b": ("M ", "1")}
        after = {"a": ("M ", "2"), "b": ("M ", "1"), "c": ("??", "3")}
        self.assertEqual(MODULE.changed_paths(before, after), ["a", "c"])


if __name__ == "__main__":
    unittest.main()
