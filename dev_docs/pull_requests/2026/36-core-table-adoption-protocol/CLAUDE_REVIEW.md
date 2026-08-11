# PR #36 — Document the core-table adoption protocol (extraction in phases)

**Author:** timujinne · **Branch:** `docs/core-table-adoption-protocol` · **Reviewed:** 2026-08-11

Adds the "adopting a table core already creates" chapter to the migration
template in three places (canonical section in `migrations.ex`, prose twin in
the README, pointer in AGENTS.md), plus core's rustler escape hatch.

## Every reference in it was checked

A docs PR whose whole value is that a reader can follow it, so the checkable
claims were checked against core rather than read:

| Reference | Result |
|---|---|
| `@excluded_exact` in the manifest generator | ✓ `phoenix_kit/dev_docs/squash/generate_baseline.exs:1056` |
| `mix phoenix_kit.repair` | ✓ `phoenix_kit/lib/mix/tasks/phoenix_kit.repair.ex` |
| `PhoenixKit.Migrations.ExpectedSchema` audits `phoenix_kit_consent_logs` | ✓ all 11 columns + 6 indexes, `owner: :core` |
| The live reference (`PhoenixKit.Modules.Legal.Migrations`) | ✓ landed in phoenix_kit_legal #16, same day |
| `{:rustler, ">= 0.0.0", optional: true}` mirrors core | ✓ `phoenix_kit/mix.exs:193`, identical form and stated reason |

The protocol as written is also internally consistent with what legal #16
actually does — the phases, the marker-namespacing rule, the "no conditional
`module absent → drop`" prohibition and the `down/1`-must-not-destroy rule all
describe that implementation rather than an idealised one.

## NITPICK — "core's V43" sends the reader to a file that no longer exists

The section opens by naming V43 as the migration that created
`phoenix_kit_consent_logs`. That is accurate *history*, but core 2.0 squashed
the chain to a V135 floor: `lib/phoenix_kit/migrations/postgres/` starts at
`v135.ex` and there is no `v43.ex` to open. A reader following the instruction
"match core's exact shape" would go looking for the wrong file.

**Fixed** with one clarifying sentence in `migrations.ex`, pointing at
`v135.ex` and `ExpectedSchema` as the shape to actually match. The historical
attribution is kept — it explains *why* the table is core's, which is the
reason the section exists.

## Note on the rustler dependency

`optional: true` means it is not imposed on consumers, and it is needed here
for the same reason as in core: MDEx's `force_build` path requires `rustler`
itself, not just `rustler_precompiled`, on OTP versions with no compatible
precompiled NIF. Because this repo is the module *template*, the entry will be
copied into every module cloned from it — which is the intent, and matches what
phoenix_kit_legal #16 did independently.

---

## Verification

- `mix test` — 43 tests, 0 failures (29 `:integration` excluded — no
  PostgreSQL in the review environment).
- `mix precommit` (incl. dialyzer) — clean, exit 0.
- The change is documentation plus one optional dependency; nothing in `lib/`
  changes behaviour, so the excluded integration tests are not load-bearing
  for this PR specifically.
