# UI Review Matrix

Comparison of Impeccable review criteria against the repo's current hard checks. "Hard" means a deterministic script or an explicit UI-lens rule, not an LLM judgment.

## Dimensions

| Dimension | Source | Our check | Evidence | Decision |
|---|---|---|---|---|
| Design specificity | `critique` | UI lens | AI | Keep |
| Nielsen heuristics | `critique` | UI lens | AI | Keep |
| Cognitive load | `critique` | UI lens | AI, snapshot | Keep |
| Contrast | `craft-floor`, `audit` | UI lens | Computed | Token pairs |
| Color tokens | `craft-floor`, `audit` | UI, scan | Static, computed | Token diff |
| Theme integrity | `audit` | UI lens | Computed | Keep |
| Spacing rhythm | `craft-floor` | UI lens | Computed | Token steps |
| Typography | `craft-floor`, `typeset` | UI lens | Computed | Measure, tracking |
| Depth/elevation | `craft-floor` | UI lens | Static, computed | Add ghost check |
| Motion | `craft-floor`, `optimize` | Perf, scan | Static, runtime | Move UI perf |
| States | `craft-floor` | UI lens | Snapshot | Keep |
| Browser surfaces | `craft-floor` | UI focus | Static, snapshot | Add checks |
| Copy | `craft-floor`, `clarify` | UI lens | AI | Keep |
| Brief coverage | `craft-floor` | UI lens | AI | Keep |
| Accessibility | `audit` | UI lens | Computed, snapshot | Keep |
| Responsive | `audit` | UI lens | Snapshot | Keep |
| Anti-patterns | `craft-floor` | UI, scan | Static, computed | Keep |
| Implementation | `audit` | UI lens | Static, AI | Keep |
| Performance | `optimize` | Perf lens | Static, measured | Move UI perf |
| Wireframing | `shape`, `new-work` | None | Authoring | New skill |

Evidence: `static` means source or regex; `computed` means rendered style or geometry; `snapshot` means state capture; `AI` means design judgment.

## `optimize` checks that are UI-specific

- Image dimensions, responsive `srcset`, lazy loading, format choice.
- Font subsetting, `font-display`, metric-compatible fallback, reflow.
- Bundle splitting, unused CSS, critical CSS, CSS containment.
- Layout thrashing, DOM depth/size, virtual lists, paint/composite boundaries.
- Animation frame budget, `will-change` discipline, bounded blur/filter/shadow areas.
- LCP, INP, CLS and measured before/after evidence.

These belong in `references/ui-performance.md`, loaded by `performance.md` when the target is UI.

## Anti-pattern checks

Deterministic or near-deterministic:

- Raw color literals versus `ui-tokens.json`.
- Gradient text: `bg-clip-text` plus transparent text.
- Decorative glass: `backdrop-blur`/`backdrop-filter` without a documented effect.
- Side-stripe borders above 1px on cards, list items, callouts, alerts.
- Hard offset shadows outside a declared neobrutalist direction.
- Glyph or emoji icons where an icon system is expected.
- System display faces on an own-world page.
- Sketch-style SVG, texture stripes, and grid overlays without a subject-world reason.
- Repeated same-size icon/heading/text card grids and nested cards.
- Hero-metric blocks and section kickers used as the page scaffold.
- Ghost cards: 1px border plus wide soft shadow; over-rounded cards.

AI judgment required:

- Whether the composition could belong to an unrelated product.
- Whether a pattern is earned by the brief.
- Whether the hierarchy, copy, and cognitive load support the task.
- Whether the visual direction is specific rather than category-default.

## Snapshot policy

Use a state matrix, not one expanded DOM:

- `preload`, `loaded`, `empty`, `error`, `disabled`, `collapsed`, `expanded`.
- Snapshot only states touched by the diff; expand more only when a finding depends on them.
- Snapshot after hydration. Use computed styles, geometry, and the accessibility tree, not raw React markup.
- Freeze animations, disable the caret, wait for fonts, set the viewport, and record theme and input method.
- Do not force every state into one DOM: hidden content contaminates accessibility, geometry, and interaction evidence.

## Design inputs

- `artifacts/ui-design.md`: intent, Dos/Don'ts, typography, density, and constraints.
- `artifacts/ui-tokens.json`: machine-readable color, spacing, type, radius, and motion tokens.

The `Token pairs`, `Token diff`, and `Token steps` decisions above mean these checks compare against `ui-tokens.json`. Neither file exists yet, so today the checks compare rendered values against each other, not against a design source.

`ui-tokens.json` needs:

- `color`: background, foreground, muted, border, and accent, per theme.
- `space`: the scale steps in use.
- `type`: family, size, weight, tracking, and measure.
- `radius`, `motion.duration`, `motion.easing`.

A token check maps each computed value to the nearest token and reports the distance. A value far from every token is off-system. Contrast is checked on token pairs per theme, not on arbitrary rendered pairs.
- Review consumes both; deterministic checks compare tokens and computed values. AI judges specificity, hierarchy, copy, and cognitive load.
