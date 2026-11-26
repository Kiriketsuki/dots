#!/usr/bin/env python3
"""Regenerate every theme output with one command.

Runs the bridge (generate_theme_css.py) first, then each per-app
update_colors.py script in the documented order. Stops at the first failure.
"""

import argparse
import hashlib
import subprocess
import sys
from collections import namedtuple
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

# package: the stow package that owns the step output.
# script: path of the script, relative to the repo root.
# args: extra arguments, relative to the repo root.
Step = namedtuple("Step", "name package script args")

BRIDGE = Step(
    "bridge",
    "theme",
    "theme/scripts/generate_theme_css.py",
    ("chrysaki/core/chrysaki.json", "theme/.config/theme/theme.css"),
)

APP_STEPS = (
    Step("btop", "btop", "btop/scripts/update_colors.py", ()),
    Step("ghostty", "ghostty", "ghostty/scripts/update_colors.py", ()),
    Step("gtk", "gtk", "gtk/scripts/update_colors.py", ()),
    Step("hypr", "hypr", "hypr/.config/hypr/scripts/update_colors.py", ()),
    Step("lazygit", "lazygit", "lazygit/.config/lazygit/scripts/update_colors.py", ()),
    Step("firefox", "firefox", "firefox/scripts/update_colors.py", ()),
)

APP_NAMES = tuple(step.name for step in APP_STEPS)


def parse_only(value):
    """Turn "btop,gtk" into a list of known app names. Raise ValueError if any is unknown."""
    names = [part.strip() for part in value.split(",") if part.strip()]
    if not names:
        raise ValueError("--only needs at least one name")
    unknown = [name for name in names if name not in APP_NAMES]
    if unknown:
        raise ValueError(
            f"unknown step: {', '.join(unknown)}. Choose from: {', '.join(APP_NAMES)}"
        )
    return names


def build_steps(only=None, skip_bridge=False):
    """Return the steps to run, always in the documented order."""
    apps = [step for step in APP_STEPS if only is None or step.name in only]
    return apps if skip_bridge else [BRIDGE, *apps]


def default_runner(step, root):
    """Run one step with the current interpreter and return its exit code."""
    command = [sys.executable, str(root / step.script)]
    command += [str(root / arg) for arg in step.args]
    return subprocess.run(command, cwd=root).returncode


def snapshot(root, package):
    """Map each changed path in a package folder to its status and content hash."""
    result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=all", "--", package],
        cwd=root, capture_output=True, text=True, check=True,
    )
    entries = {}
    for line in result.stdout.splitlines():
        status, path = line[:2], line[3:].split(" -> ")[-1].strip('"')
        target = root / path
        digest = hashlib.sha1(target.read_bytes()).hexdigest() if target.is_file() else ""
        entries[path] = (status, digest)
    return entries


def changed_paths(before, after):
    """Return the paths whose status or content differs between two snapshots."""
    return sorted(path for path in after if before.get(path) != after[path]) + sorted(
        path for path in before if path not in after
    )


def run_all(steps, root, runner=default_runner, snap=snapshot):
    """Run the steps in order. Return a list of (step, exit code, changed paths).

    The list ends at the first failed step.
    """
    results = []
    for step in steps:
        before = snap(root, step.package)
        print(f"==> {step.name}: {step.script}")
        code = runner(step, root)
        changed = changed_paths(before, snap(root, step.package))
        results.append((step, code, changed))
        if code != 0:
            print(f"step failed: {step.name} (exit code {code})", file=sys.stderr)
            break
    return results


def print_summary(results, planned):
    print("\nSummary")
    done = {step.name: code for step, code, _ in results}
    for step in planned:
        if step.name not in done:
            state = "not run"
        else:
            state = "ok" if done[step.name] == 0 else f"failed (exit {done[step.name]})"
        print(f"  {step.name}: {state}")
    changed = sorted({path for _, _, paths in results for path in paths})
    print("Changed output files:" if changed else "Changed output files: none")
    for path in changed:
        print(f"  {path}")


def stow_packages(results):
    """Return the packages of successful steps that changed files, without repeats."""
    packages = []
    for step, code, changed in results:
        if code == 0 and changed and step.package not in packages:
            packages.append(step.package)
    return packages


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help=f"comma list of app steps: {', '.join(APP_NAMES)}")
    parser.add_argument("--skip-bridge", action="store_true", help="do not run generate_theme_css.py")
    parser.add_argument("--stow", action="store_true", help="run stow --restow for changed packages")
    args = parser.parse_args(argv)
    try:
        args.only_names = parse_only(args.only) if args.only is not None else None
    except ValueError as error:
        parser.error(str(error))
    return args


def main(argv=None, runner=default_runner, snap=snapshot, root=REPO_ROOT):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    planned = build_steps(args.only_names, args.skip_bridge)
    results = run_all(planned, root, runner, snap)
    print_summary(results, planned)

    failed = any(code != 0 for _, code, _ in results)
    for package in stow_packages(results):
        command = ["stow", "--restow", package]
        if args.stow and not failed:
            print(f"running: {' '.join(command)}")
            code = subprocess.run(command, cwd=root).returncode
            if code != 0:
                print(f"stow failed for {package} (exit code {code})", file=sys.stderr)
                return code
        else:
            print(f"would run: {' '.join(command)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
