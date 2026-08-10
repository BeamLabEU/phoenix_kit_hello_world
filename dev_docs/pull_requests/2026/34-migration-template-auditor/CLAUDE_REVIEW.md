# PR #34 — Harden the migration template and ship an auditor for it

**Reviewed:** 2026-08-10 · **Author:** timujinne · **Verdict:** merged, **with
two fixes applied on `main`.** Released in **0.2.0**.

+667 / −67 across 4 files. Reviewed as part of the phoenix_kit 2.0 sweep.

## Why this matters more than a template tweak

This package is the module template — every `phoenix_kit_*` module's migration
coordinator was copied from it. So a bug in the snippet here is a bug that has
already been copied into production modules, which is exactly what the PR
found: auditing `phoenix_kit_legal` turned up a coordinator wrong in five ways
while reporting itself healthy, and **three of those were wrong because this
template's snippet was wrong.**

The three template bugs are all real and all of the same shape — a failure that
disguises itself as a healthy reading:

1. **`String.to_integer/1` on the version comment raises** on a non-numeric
   comment, and the raise lands in a blanket `rescue _ -> 0`, so a *populated*
   table reports "not installed". The slot is not always free — core's V43 puts
   a prose description on `phoenix_kit_consent_logs`. Now `Integer.parse/1`
   with an `@initial_version` fallback.
2. **`migrated_version_runtime/1` swallowing everything into `0`** means an
   invalid `--prefix` reads as a fresh install, and the updater then generates
   DDL against live data. Re-raising `ArgumentError` matches core's own
   `PhoenixKit.Migrations.Postgres.migrated_version_runtime/1`.
3. **`up_v1/1` ensured the uuid function but not pgcrypto**, so
   `uuid_generate_v7()` is created and then fails on first insert — the failure
   is displaced from migration time to runtime.

The documented rules are the more valuable half. Two are genuinely non-obvious:
**core's migrations run before module migrations in the same task**, so if core
also ships your table's DDL, core wins on every host and your `up/1` is dead
code drifting out of sync (`phoenix_kit_legal` is in exactly that state against
core V43); and the **ordering trap** — while the version is inferred from table
existence, an always-dropping `down/1` is unreachable and looks harmless, so
fixing the marker *alone* arms it.

## Fixed on `main`

Both are gate failures introduced by the PR, not design problems:

- **`mix credo --strict` failed** — "Function body is nested too deep (max
  depth is 2, was 3)" at `check_version_marker/2`. Extracted the `case` into
  `inspect_version_marker/2`, which also reads better: the outer function now
  answers "can we audit this at all?" and the inner one "what does the marker
  say?".
- **`mix dialyzer` failed** with `Function Mix.shell/0 does not exist` (×4) and
  `callback_info_missing` for the `Mix.Task` behaviour. This package's
  `plt_add_apps` was `[:phoenix_kit]`; the auditor is the first code here to be
  a Mix task, so `:mix` had to join the PLT. Matches what
  `phoenix_kit_billing`, `phoenix_kit_emails` and others already do.

## Carried forward

The `phoenix_kit_legal` finding is **not fixed by this PR** — it fixes the
template, not the module that was copied from it. Legal is a tier-2 module in
this sweep; the conflict between core's V43 and legal's own DDL is recorded in
the sweep document as an open item, since reconciling it needs a real migration
step and is well beyond a pin bump.

## Verification

| Check | Result |
|---|---|
| `mix precommit` | **passes** against core 2.0.0, after both fixes |
| `mix test` | **42 tests, 0 failures** (29 excluded — no Postgres available) |

The auditor itself needs a live database to do anything, so it is reviewed by
reading only.
