# UI Review Lens

Use when the diff renders or changes a user interface.

## Authoring

1. Decompose compound primitives into parts (`Root`, `Trigger`, `Portal`, `Content`, `Close`); use context instead of prop drilling.
2. Model async state as a strict union: `idle`, `loading`, `success`, `empty`, `error`; cancel stale work with `AbortController`.
3. Wire WAI-ARIA roles and state (`aria-expanded`, `aria-controls`), keyboard navigation, and visible focus.
4. Support `asChild` composition and ref forwarding; merge classes with `cn()`.
5. Animate only compositor properties (`transform`, `opacity`); respect `prefers-reduced-motion`.

## Audit

Render the target at desktop (>=1024px) and mobile (375x667), in light and dark themes, and sample hover and focus states.

- Every interactive control needs an accessible name, visible focus indicator, and keyboard trigger.
- Touch targets are at least 44x44px; text contrast is at least 4.5:1.
- Compare computed padding, margin, and gap against the density profile.
- Resolve computed colors across themes; report off-palette nodes.
- Never suppress focus rings without an equivalent visible focus ring.
- Never introduce raw color literals in components; fix token mappings.

## Rules

- Primitives stay headless and unstyled by default; styles merge via `cn()`.
- Never use disjoint flags (`isLoading && isError`); use a strict discriminated union.
- Keep micro-interactions under 200ms.
- Write findings with `file:line` and a remediation diff to `artifacts/review/ui-<topic>.md`.
- Verify: zero off-palette colors, zero accessibility violations, and conformance to the target density profile.
