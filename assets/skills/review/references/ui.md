# UI Review Lens

Use when the diff renders or changes a user interface.

## Authoring

1. Decompose compound primitives into parts (`Root`, `Trigger`, `Portal`, `Content`, `Close`); use context instead of prop drilling.
2. Model async state as a strict union: `idle`, `loading`, `success`, `empty`, `error`; cancel stale work with `AbortController`.
3. Wire WAI-ARIA roles and state (`aria-expanded`, `aria-controls`), keyboard navigation, and visible focus.
4. Support `asChild` composition and ref forwarding; merge classes with `cn()`.
5. Animate only compositor properties (`transform`, `opacity`); respect `prefers-reduced-motion`.

## Design specificity

- Decide whether this composition could belong to an unrelated product unchanged; if yes, report it.
- Check hierarchy, information architecture, cognitive load, and whether the primary action is findable within seconds.
- Check brief coverage: every requirement in `artifacts/ui-design.md` is present and findable within seconds; list shipped features the brief never asked for.
- Compare against `artifacts/ui-design.md` when present; treat its tokens and constraints as authoritative.

## Anti-patterns

Read `references/slop.md`; flag its matches. Treat them as findings, not unconditional bans: a documented brief can earn any pattern, and the finding must name the earning line.

## Heuristics

- Check visibility of system status, match to the user's world, user control, consistency, error prevention, recognition over recall, flexibility, minimalist design, error recovery, and help.
- Flag more than four primary choices, hidden state, working-memory load, and unchunked data.
- Report severity: P0 blocks use, P1 blocks the primary task, P2 degrades trust or speed, P3 is polish.

## Audit

Read `artifacts/ui-design.md` when present; use its tokens, density, typography, and constraints as the design source. If it is absent, infer them from the diff.

Run `ui-scrape --source .` for source patterns in changed UI files. Treat matches as evidence, not findings; verify each match in context.

If a browser is available, render the target at desktop (>=1024px) and mobile (375x667), in light and dark themes, and sample hover and focus states. Prefer `ui-scrape --url <url> --wait-for <selector> --state <name> [--expand] [--theme light|dark]`; it reports findings derived from rendered geometry and computed colors, plus a candidate list and tab order, as JSON. `--expand` opens each ARIA disclosure one at a time and reports per-state deltas. Without the tool or a browser, inspect supplied screenshots and list every unrendered check under unverified.

Exercise preload, loaded, empty, error, disabled, collapsed, and expanded; snapshot only the states the diff touches.

- Every interactive control needs an accessible name, visible focus indicator, and keyboard trigger.
- Widget roles carry their states: `aria-expanded`, `aria-controls`, `aria-selected`, `aria-pressed`, `aria-current`. Async status uses a live region. No ARIA overrides native semantics without cause.
- Touch targets are at least 44x44px; text contrast is at least 4.5:1.
- Body measure stays 65-75ch; tracking stays at or above -0.04em; no text overflows its container. Display sizes follow `artifacts/ui-design.md`, not a fixed ceiling.
- Compare computed padding, margin, and gap against the density profile.
- Declare elevation once, border or shadow. Flag a 1px border under a wide soft shadow as a ghost card. Match radii to `artifacts/ui-design.md`; without a spec, flag mixed radii on comparable surfaces, not a numeric range.
- Theme selection, caret, scrollbars, focus rings, underline offset, and tabular numerals from the palette; browser defaults belong to no design system.
- Resolve computed colors across themes; report off-palette nodes.
- Never suppress focus rings without an equivalent visible focus ring.
- Never introduce raw color literals in components; fix token mappings.
- Cite source and rendered evidence: viewport, theme, input method, and what was not exercised.

## Rules

- Primitives stay headless and unstyled by default; styles merge via `cn()`.
- Never use disjoint flags (`isLoading && isError`); use a strict discriminated union.
- Write findings with `file:line` and a remediation diff to `artifacts/review/ui-<topic>.md`.
- Verify: zero off-palette colors, zero accessibility violations, and conformance to the target density profile.
