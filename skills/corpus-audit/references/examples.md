# Corpus-Audit Examples

## Bad

- Auditing only the current session; use `retro` instead.
- Listing tool errors without connecting them to harness prompt or rule remedies.

## Good

- Ingest five past sessions, show that three independently failed on npm before finding deno, and propose a strict workspace stack rule for `author-harness`.
