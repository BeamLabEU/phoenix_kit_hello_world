# PR #33 — Add the reference project-extension provider

**Reviewed:** 2026-08-10 · **Author:** mdon · **Verdict:** merged, no changes
required. Released in **0.2.0**.

+242 / −24 across 6 files. Reviewed as part of the phoenix_kit 2.0 sweep.

Adds `phoenix_kit_project_extensions/0` and `Web.ProjectHelloTabLive` as the
**reference implementation** of the projects-hub extension contract, which is
this package's whole reason to exist — the same contract
`phoenix_kit_locations#10` and `phoenix_kit_entities#26` implement for real in
this same sweep. Having the canonical minimal version live in the template
module is the right home for it, and `test/…/project_extension_test.exs` pins
the contributed shape so the template cannot silently drift from what the hub
expects.

Verified: `mix precommit` passes against core 2.0.0; `mix test` 42 tests, 0
failures (29 excluded — no Postgres available).
