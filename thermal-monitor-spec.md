# Feature: Thermal Monitor

> **STATUS: IMPLEMENTED**. The thermal script, status segment, and `prefix + m` popup binding are shipped. This spec documents the as-built behavior.

## Overview

**User Story**: As a power user, I want a persistent thermal indicator in my tmux status bar and a detailed popup panel so that I can catch runaway processes before they keep the laptop hot for minutes unnoticed.

**Problem**: Thermal events are currently invisible from inside tmux unless I stop and run `sensors` manually. That is too slow for the actual failure mode here: a browser, test runner, or background process quietly pins the CPU, fans ramp up, and the machine sits at 80C+ until I notice by feel.

**Repo Grounding**:
- Editable tmux source lives in `chrysaki/tmux/*`
- Live tmux config is exposed via the stow package under `tmux/.config/tmux/*`
- New helper scripts under `chrysaki/tmux/scripts/` must also be exposed through `tmux/.config/tmux/scripts/`
- The current right status block only shows git branch, host, time, and date
- tmux already refreshes the status line every second via `status-interval 1`

**Out of Scope**:
- GPU temperature readout (this machine exposes GPU fan RPM, but no reliable discrete GPU temp via `lm_sensors`)
- Historical graphing, sparklines, or any time-series persistence
- Desktop notifications, sounds, or threshold-triggered alerts
- Fan control, process killing, or any other active thermal remediation
- Waybar or AGS integration

---

## Success Condition

> This feature is complete when tmux shows a color-coded thermal segment on every status refresh, `prefix + m` opens a centered popup with live thermal detail for all available sensors, and the implementation fits the existing Chrysaki tmux source/stow layout without breaking branch, host, time, or date status content.

---

## Decisions

| # | Decision | Reason |
|:--|:---------|:-------|
| 1 | Sensor selectors are machine-specific with explicit fallbacks, not user-configurable | This is a personal dotfiles repo and the local sensor surface is already known |
| 2 | CPU temperature is sourced from `k10temp-pci-00c3.Tctl.temp1_input`, with `acpitz-acpi-0.temp1.temp1_input` as fallback | Matches the current machine and gives a stable primary CPU reading |
| 3 | Fan data comes from `asus-isa-000a` and `acpi_fan-isa-0000`; the bar shows the highest non-zero RPM while the popup shows per-sensor rows | Compact bar, detailed popup |
| 4 | Battery data comes from `/sys/class/power_supply/BAT1/*`, not from `sensors -j` | Sysfs exposes status/capacity cleanly; `sensors -j` does not |
| 5 | The feature is implemented as one executable Python script with `--bar` and `--popup` modes | Keeps parsing and presentation logic in one place |
| 6 | The popup owns its own redraw loop and keyboard handling; no background daemon is introduced | tmux already drives the bar refresh cadence |

---

## Scope

### Must-Have
- **Status bar segment**: Add a compact `icon temp icon max_fan` segment to `status-right`, inserted between the host block and the time block. Done when the segment appears on every tmux status refresh without truncating the rest of the standard status content.
- **Threshold coloring**: Color the temperature text by CPU threshold using current Chrysaki values: `<60C` teal-light (`#20969c`), `60C-79.9C` blonde (`#FBB13C`), `>=80C` error-light (`#b53f4a`). Done when the segment color changes solely from the measured CPU temperature.
- **Non-CPU-temp thresholds**: Other rows carry their own color rules. Fan rows color teal-light below `4000` RPM and blonde at or above `4000` RPM. The load average colors teal-light below `4.0`, blonde below `8.0`, and error-light at or above `8.0`. NVMe composite temps and the RAM temp reuse the same CPU temperature thresholds (teal-light `<60C`, blonde `60C-79.9C`, error-light `>=80C`).
- **Detailed popup**: `prefix + m` opens a centered popup titled `Thermal Monitor` showing CPU temp, CPU fan, GPU fan, highest fan, each detected NVMe composite temp, RAM temp with alarm marker, Top-CPU and Top-RAM read-only process tables, load average, and battery information. Done when the popup stays readable at the existing tmux popup scale and refreshes in place every 2 seconds.
- **Single script**: Create `chrysaki/tmux/scripts/thermal.py` as the only feature-specific implementation file. Done when both bar and popup modes run from that script.
- **Stow exposure**: Add `tmux/.config/tmux/scripts/thermal.py` as the live path exposed by the repo. Done when the stow package contains the new script path alongside the existing tmux helper scripts.
- **Help discoverability**: Add the new binding to `chrysaki/tmux/help.sh`. Done when `prefix + ?` documents `prefix + m`.
- **Graceful degradation**: If `sensors` is missing or returns invalid JSON, the bar shows muted `N/A` and the popup shows an explicit error panel. If only some sensors are missing, unaffected rows still render and missing rows show `N/A`.
- **No extra runtime services**: The status segment runs once per tmux refresh tick and exits immediately. The popup refresh loop exists only while the popup is open.

### Should-Have
- **Heat bars**: Temperature rows in the popup include a short visual bar to improve scanability.
- **Command palette entry**: Add an `Open thermal monitor` action to `chrysaki/tmux/scripts/palette.sh`.
- **Resize-aware layout**: Popup rendering reflows cleanly if the user resizes the tmux client while the popup is open.

### Nice-to-Have
- **Human-friendly NVMe labels**: Replace generic `NVMe 1` / `NVMe 2` labels with model or stable device identifiers if they can be derived cheaply.
- **Duplicate fan suppression**: If `acpi_fan` is clearly duplicating an ASUS-exposed fan, hide the duplicate row in the popup while still computing the correct maximum RPM.

---

## Technical Plan

**Affected Components**:

| Component | Action |
|:----------|:-------|
| `chrysaki/tmux/scripts/thermal.py` | Create executable Python script that reads sensors, normalizes values, and renders `--bar` / `--popup` |
| `tmux/.config/tmux/scripts/thermal.py` | Create symlink to the Chrysaki source script so stow exposes it at `~/.config/tmux/scripts/thermal.py` |
| `chrysaki/tmux/chrysaki.conf` | Modify `status-right` and increase `status-right-length` from `80` to a value that safely fits the new segment |
| `chrysaki/tmux/tmux.conf` | Add `prefix + m` popup binding using the existing centered popup styling |
| `chrysaki/tmux/help.sh` | Add help text for the thermal monitor binding |
| `chrysaki/tmux/scripts/palette.sh` | Add command-palette entry for the popup if the Should-Have item is accepted during implementation |

**Data Model Changes**: None. The feature is read-only and stateless across invocations.

**Runtime Data Sources**:

| Metric | Primary Source | Fallback / Notes |
|:-------|:---------------|:-----------------|
| CPU temp | `k10temp-pci-00c3.Tctl.temp1_input` | Fallback to `acpitz-acpi-0.temp1.temp1_input` |
| CPU fan | `asus-isa-000a.cpu_fan.fan1_input` | Show `N/A` if missing |
| GPU fan | `asus-isa-000a.gpu_fan.fan2_input` | Show `N/A` if missing |
| Extra/system fan | `acpi_fan-isa-0000.fan1.fan1_input` | Optional popup row; include in max-RPM calculation if non-zero |
| NVMe temps | Every `nvme-pci-*` entry using `Composite.temp1_input` | Preserve deterministic row order |
| RAM temp | `spd5118-i2c-3-50.temp1.temp1_input` | Warning marker when `temp1_max_alarm == 1` |
| Load average | `os.getloadavg()` | Render `1m / 5m / 15m` |
| Battery | `/sys/class/power_supply/BAT1/{status,capacity,voltage_now,current_now}` | If `BAT1` is absent, render battery row as `N/A` instead of failing the popup |

**Rendering Contract**:
- `--bar` is one-shot and prints tmux-formatted text only; no ANSI escapes, no sleep loop, no background state
- `--popup` owns the interactive loop, redraws every 2 seconds, exits on `q`, `Esc`, or `Ctrl-C`, and restores terminal mode on exit
- Popup rendering uses ANSI 24-bit color escapes to match the existing Chrysaki popup style used by `help.sh`
- The script keeps its color constants in one small block at the top, using the canonical Chrysaki hex values (e.g. Error Light `#b53f4a` from chrysaki/CLAUDE.md → Secondary Accents → Error Light)
- The popup should clear and redraw the screen in place rather than appending frames

**Dependencies**:
- `lm_sensors` package with working `sensors -j`
- Python 3 stdlib only: `json`, `os`, `re`, `select`, `shutil`, `signal`, `subprocess`, `sys`, `termios`, `tty`, `dataclasses`, `pathlib`, `typing`
- Existing tmux popup support from tmux 3.2+
- IosevkaTermSlab Nerd Font for status-bar glyphs

**Risks**:

| Risk | Likelihood | Mitigation |
|:-----|:-----------|:-----------|
| Sensor chip names drift after BIOS, kernel, or `lm_sensors` changes | Medium | Use a small ordered fallback list per metric and degrade per-row instead of hard-failing |
| tmux popup keyboard handling is fragile inside a pseudo-TTY | Medium | Use the same `TERM` setup pattern as existing tmux popup scripts and keep input handling minimal (`q`, `Esc`, `Ctrl-C`) |
| Added status content causes right-side truncation on long branch names | Medium | Increase `status-right-length`, test on a long branch, and keep the thermal segment compact |
| Fan telemetry includes duplicate or zero-RPM readings | Medium | Filter zero values from max-RPM logic and treat duplicate rows as presentation-only cleanup |
| Runtime dependency on `sensors -j` adds overhead every second | Low | Parse once per invocation and keep `--bar` strictly one-shot with no extra subprocesses |

---

## Acceptance Scenarios

```gherkin
Feature: Thermal Monitor
  As a power user
  I want thermal monitoring in tmux
  So that I notice heat issues immediately while staying inside my terminal workflow

  Background:
    Given tmux is running with the Chrysaki theme loaded
    And the thermal feature is exposed at ~/.config/tmux/scripts/thermal.py

  Rule: Status bar shows a compact thermal summary

    Scenario Outline: CPU temperature controls the segment color
      Given the CPU temperature reported by the thermal script is <temp>
      When tmux refreshes the status line
      Then the thermal segment is colored <color>
      And it appears between the host block and the time block

      Examples:
        | temp  | color |
        | 58.0C | teal-light |
        | 72.0C | blonde |
        | 84.0C | error-light |

    Scenario: Highest non-zero fan RPM is shown in the bar
      Given CPU fan is 3300 RPM
      And GPU fan is 3400 RPM
      And ACPI fan is 0 RPM
      When tmux refreshes the status line
      Then the displayed fan RPM is 3400

    Scenario: sensors is unavailable
      Given the sensors command is missing or returns invalid JSON
      When tmux refreshes the status line
      Then the thermal segment shows muted N/A
      And tmux does not lose the rest of the right-side status content

  Rule: Popup shows live thermal detail

    Scenario: Popup opens from prefix + m
      When the user presses prefix + m
      Then a centered popup titled "Thermal Monitor" opens
      And it shows CPU temp, fan rows, NVMe rows, RAM temp, load average, and battery data

    Scenario: Popup refreshes in place
      Given the popup is open
      When 2 seconds elapse
      Then the displayed readings update in place
      And the popup remains open

    Scenario: Partial sensor failure only affects missing rows
      Given CPU temp and fans are available
      And one NVMe sensor is missing
      When the popup renders
      Then CPU and fan rows show live values
      And the missing NVMe row shows N/A
      And the popup does not collapse into a global error state

    Scenario: RAM alarm is visible
      Given RAM temperature is present
      And temp1_max_alarm equals 1
      When the popup renders
      Then the RAM row shows a warning marker

    Scenario: Popup exits cleanly
      Given the popup is open
      When the user presses q or Esc
      Then the popup closes
      And tmux returns focus to the previous pane

  Rule: Feature matches current tmux UX surfaces

    Scenario: Help popup documents the new binding
      Given the user opens tmux help with prefix + ?
      Then the help popup includes prefix + m for the thermal monitor
```

---

## Task Breakdown

| ID | Task | Priority | Dependencies | Status |
|:---|:-----|:---------|:-------------|:-------|
| T1 | Create `chrysaki/tmux/scripts/thermal.py` with sensor parsing and normalized metric extraction | High | None | pending |
| T1.1 | Implement `--bar` mode with threshold coloring and max-fan selection | High | T1 | pending |
| T1.2 | Implement `--popup` mode with ANSI redraw loop and key handling | High | T1 | pending |
| T1.3 | Add battery and load-average collection | High | T1 | pending |
| T1.4 | Add graceful degradation for missing command, invalid JSON, and partial sensor absence | High | T1 | pending |
| T2 | Add `tmux/.config/tmux/scripts/thermal.py` symlink so the script is live under the stow package | High | T1 | pending |
| T3 | Modify `chrysaki/tmux/chrysaki.conf` to insert the segment and increase `status-right-length` | High | T1.1 | pending |
| T4 | Add `prefix + m` popup binding to `chrysaki/tmux/tmux.conf` using existing popup styling | High | T1.2 | pending |
| T4.1 | Add the new binding to `chrysaki/tmux/help.sh` | High | T4 | pending |
| T4.2 | Add command-palette entry to `chrysaki/tmux/scripts/palette.sh` | Medium | T4 | pending |
| T5 | Reload tmux config and verify the bar renders without truncating branch, host, time, or date | High | T2, T3, T4 | pending |
| T5.1 | Verify popup refresh, exit keys, and per-row fallback handling | High | T4 | pending |

---

## Exit Criteria

- [ ] `~/.config/tmux/scripts/thermal.py --bar` returns quickly and prints a valid tmux-formatted segment
- [ ] `~/.config/tmux/scripts/thermal.py --popup` refreshes every 2 seconds and exits on `q` or `Esc`
- [ ] `prefix + m` opens the thermal popup from tmux
- [ ] The right status block still includes git branch, host, time, and date after the thermal segment is added
- [ ] `tmux/.config/tmux/scripts/thermal.py` exists in the repo and resolves to the Chrysaki source script
- [ ] Missing `sensors` or missing individual sensor rows never crash the bar or popup
- [ ] `prefix + ?` help text documents the thermal monitor binding

---

## References

- Existing popup patterns: `chrysaki/tmux/tmux.conf`
- Existing right-side status block: `chrysaki/tmux/chrysaki.conf`
- Existing popup rendering style: `chrysaki/tmux/help.sh`
- Existing command-palette integration: `chrysaki/tmux/scripts/palette.sh`
- Live tmux stow layout: `tmux/.config/tmux/` and `tmux/.config/tmux/scripts/`
- Current Chrysaki color values: `theme/.config/theme/theme.css`
- Current machine sensor keys validated from `sensors -j`: `k10temp-pci-00c3`, `asus-isa-000a`, `nvme-pci-0500`, `nvme-pci-0200`, `spd5118-i2c-3-50`, `acpi_fan-isa-0000`
