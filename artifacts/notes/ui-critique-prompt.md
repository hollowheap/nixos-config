# One-Shot UI Critique Prompt

Paste the block below with `<BRIEF>`, `<TARGET>`, and `<TOKENS>` filled in. It merges Impeccable's craft-floor coverage check with its design critique into one pass.

```text
Review <TARGET> against <BRIEF>. This is a read-only review. Do not edit files.

INPUTS
- BRIEF: <BRIEF>
- TARGET: <TARGET>
- TOKENS: <TOKENS or "none">
- If a field is missing, mark it unverified and continue. Do not ask questions.

PASS 1 - BRIEF COVERAGE
1. Extract every requirement, claim, constraint, and named audience from the brief. Number them R1, R2, ...
2. Find visible evidence for each: file:line, selector, computed value, or screenshot region.
3. Verdict per requirement: covered | partial | missing | contradicted.
4. List shipped features the brief never asked for as scope drift.
5. Findability test: name the first action a newcomer takes, where the eye lands first, and how many seconds that takes.
6. If the target is an AI surface, also check: pre-response state, streaming, stop and retry, model or cost disclosure, offline or degraded behavior.

PASS 2 - CRITIQUE
Design specificity:
- Could this composition ship unchanged for an unrelated product? Cite the evidence that ties it to this brief. If none exists, say so first.

Structure:
- Hierarchy, information architecture, primary action, reading order.
- Cognitive load: more than four competing choices, hidden state, recall load, unchunked data.
- Emotional journey: peak-end, emotional valleys, reassurance at high-stakes moments.

States:
- hover, focus, active, disabled, loading, empty, error, long content, overflow, reduced motion.
- Report a state only if you can point at it or prove it absent.

Craft floor:
- Contrast 4.5:1 body, 3:1 large text.
- Body measure 65-75ch, display <=6rem, tracking >= -0.04em, no text overflow.
- Spacing rhythm: tight groups, more space above a heading than below.
- Depth: one elevation system; flag 1px border plus wide soft shadow as a ghost card.
- Browser surfaces: selection, caret, scrollbar, focus ring, underline offset, tabular numerals.
- Copy: controls name their action; errors name the problem and the recovery.

Slop test (category defaults; name the brief line that earns one, or flag it):
- Scaffolds: nested cards, icon-tile stack, kicker or eyebrow above a heading, hero eyebrow chip, 01/02/03 labels, oversized H1, one spacing gap everywhere, edge-flush cards, same-size card grid.
- Surfaces: side-stripe border, border accent on a rounded card, hairline border plus wide shadow, hard offset shadow, glow or radial halo, decorative glass, buried image, occluded text.
- Palette and type: indigo/violet on near-black, cream plus serif plus terracotta, default blue, Inter or Poppins as the only voice, two sizes and two weights, italic serif display, gradient text, crushed tracking, all-caps body, justified text, measure over 75ch, orphan heading word.
- Media and motion: shape-assembled illustration, organic clip-path, grid or stripe background without a subject reason, marquee, bounce easing, pulsing dot, blinking cursor.
- Copy: em-dash overuse, marketing buzzwords, aphoristic cadence, theater framing, repeated text inside one container.
- Runtime: broken image, uncaught script error, content hidden at rest, text overflow, positioned child clipped by an overflow ancestor, one column stretching the first viewport, low contrast, gray on color, skipped heading.

Accessibility:
- Accessible names, keyboard path, visible focus, 44px targets, contrast.

Performance (observed only):
- Layout thrash, oversized images, animation on non-compositor properties, unbounded blur or filter areas.

PASS 3 - SYNTHESIS
- 2-3 strengths, each with evidence.
- 3-5 priority issues, ordered by damage to the primary task.
- Severity: P0 blocks use, P1 blocks the primary task, P2 degrades trust or speed, P3 polish.
- One provocative question that would change the design.
- Unverified list: what you could not inspect.

RULES
- Evidence or silence. Every finding cites file:line, selector, computed value, or screenshot region.
- Do not invent states, copy, or data you did not see.
- No praise padding, no restating the brief, no percentage scores.
- Do not propose a redesign unless a P0 or P1 requires it.
- Keep table cells short. Put detail below the table.

OUTPUT (exact headings, in order)
1. Verdict - three lines maximum.
2. Coverage - table: # | Requirement | Evidence | Verdict
3. Critique - table: Axis | Finding | Evidence | Severity
4. Strengths
5. Priority issues - each with severity, evidence, and the smallest fix.
6. Unverified
7. Question
```

## Notes

- The slop test mirrors `assets/skills/review/references/slop.md`, which is distilled from Impeccable's 60-rule registry. Keep the two in sync.
- Pass 1 and Pass 2 stay independent until the synthesis. Coverage evidence must not anchor the critique.
- The slop list is judgment, not a ban list. The brief can earn any pattern.
- Drop the "AI surface" line for products without a model call.
