# Handoff: Ghostty Hex Wave Shader Tuning

## Situation
Iterative tuning of a Ghostty terminal shader (`grain.glsl`) that renders a hex grid with a travelling wave animation. The wave sweeps across the screen in a random direction each cycle, spinning and expanding hexes as it passes. Work has been on main branch, uncommitted.

## Current State
- Branch: `main`
- Uncommitted: `ghostty/` is entirely untracked (new stow package)
- Tests: N/A (visual shader, verify by opening Ghostty)
- What works: hex grid with gaps, triangles at corners, wave with spin+growth, base ring suppression during spin, vignette
- What's incomplete: purely cosmetic tuning — user is iterating on brightness, sizing, and feel

## Key Files
- `ghostty/.config/ghostty/shaders/grain.glsl` — the entire shader, 165 lines

## Decisions Made
- **Hard `step()` edges, no feathering** — user explicitly rejected smoothstep AA on hex rings; uses `step(0.490*k, d) * (1.0 - step(0.510*k, d))` for crisp 2px lines
- **60° spin, not 360°** — `spinAngle = progress * 1.04720` (π/3 radians total rotation per wave pass)
- **All hexes spin** — removed parity system; every hex in wave spins and grows
- **cellSize = 120** — doubled from original 60 for larger hexes
- **Ring radius 0.43** (not 0.5) — creates visible gaps between hexes; 0.48 was too tight, 0.333 was too sparse
- **ringScale = 1.0 + 0.038 * growPop** — expanded ring barely larger than base, fills gap without overlapping neighbours
- **normalMask = 1.0 - smoothstep(0.2, 0.7, growPop)** — base ring fully hidden when growPop > 0.7, not just at dx=0
- **Triangles at hex corners** — equilateral triangles (IQ SDF, `triSDF` function), alternating up/down at the 6 voronoi vertices; `triSize = 0.018`; light up with waveCol when wave passes (`growPop * 0.099`)
- **Wave speed = 2.5** (halved from 5.0), period stays 50

## Failed Approaches
- `replace_all` of `0.48→0.43` corrupted `0.485` inside hexRing smoothstep to `0.435`, creating a massive soft ramp that made all rings blurry — caught and fixed; **be careful with replace_all on numeric substrings**
- Groove-style hexRing (`smoothstep` with 0.02k transition zones) was too thick/soft for user's taste
- Parity system (every-other hex spins) was removed by user request
- Ring radius 0.333 created way too large gaps (hexes only 2/3 of cell)
- Multiple brightness reduction rounds accumulated to near-invisible values; had to bump back up

## Active Constraints
- User wants very subtle hex lines — brightness has been reduced many times
- No feathering on hex ring edges (hard `step`)
- Triangles should be small (0.018 triSDF size)
- Visual verification only — open Ghostty terminal to see changes

## Current Brightness Values
| Element | Value |
|---------|-------|
| Base hex grid | `vec3(0.07, 0.16, 0.17) * baseEdge * 0.0275 * normalMask` |
| Triangles (static) | `vec3(0.09, 0.22, 0.24) * triMask * 0.033` |
| Triangles (wave boost) | `waveCol * triMask * growPop * 0.099` |
| Wave ring | `waveCol * edge * mix(0.00165, 0.0077, pop) * normalMask` |
| Expanded spin rings | `bestCol * bestEdge * 0.0545` |

## Next Steps
1. Continue cosmetic tuning per user feedback (brightness, sizing, timing)
2. Potentially commit as part of the `ghostty/` stow package
3. User may want to adjust wave speed, triangle size, or ring scale further

## Open Questions
- User hasn't indicated when they want to commit this work
- The header comment still says "1.25x peak growth" but actual scale is 1.038x — minor
