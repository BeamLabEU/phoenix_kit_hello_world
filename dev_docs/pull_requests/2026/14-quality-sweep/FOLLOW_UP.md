# Follow-up Items for PR #14 — Quality sweep

After-action record for the quality sweep that landed as PR #14
(`mdon:main → BeamLabEU:main`). Two batches so far.

## Batch 1 (original sweep — 2026-04-25)

The original quality sweep landed as commits `2527f01`
(ComponentsLive decomposition into 22 per-section function
components), `8b292f8` (the main quality refactor — full test infra,
gettext wraps, status-label literal-call helpers, stable
`enabled?/0`), and `c1c2674` (`enabled?/0` `catch :exit, _` for
sandbox-shutdown stability).

Tests: 30 → 50, 10/10 stable, `mix precommit` clean.

## Batch 2 (re-validation — 2026-04-26)

Second module under the post-Apr re-validation template (canonical:
`BeamLabEU/phoenix_kit_ai#5` and `BeamLabEU/phoenix_kit_locations#3`).
Phase 1 PR triage re-verified clean — the 4 PR follow-ups (#6, #11,
#12, #13) all hold. C12 triage (3 Explore agents) + C12.5 deep dive
surfaced the items below.

### Fixed (Batch 2 — 2026-04-26)

- ~~**C12 #2 [HIGH]** Ungettext'd headings + dt labels in
  `hello_live.ex`~~ — wrapped ~22 user-facing text spans via 32
  `Gettext.gettext(PhoenixKitWeb.Gettext, ...)` call sites (long
  paragraphs split across multiple calls due to inline `<code>` /
  `<.link>` interpolation): card titles ("Hello World Plugin",
  "Activity Logging Demo", "Module Info", "Current User", "Explore
  the showcase", "Next Steps"), every dt label in the Module Info /
  Current User cards (Module, Key, Version, Enabled, Email, Roles,
  Admin?, Module access?), the "Show the code pattern" details
  summary, and the next-steps list body text. The original sweep
  wrapped flash messages, status badges, and explicit feature-callout
  copy but missed the structural card titles and dt labels — pinned
  with new "renders gettext-wrapped dt labels in both info cards"
  test that asserts the exact literal inside a `<dt>` tag for each
  of the 8 labels.

- ~~**C12 #2 [HIGH]** Ungettext'd `title="View details"` in
  `events_live.ex:314`~~ — wrapped via the verbose form
  (`title={Gettext.gettext(PhoenixKitWeb.Gettext, "View details")}`).
  Matches the rest of `events_live.ex` which already uses the
  verbose form because it `use Phoenix.LiveView`s directly (no
  auto-imported gettext). Pinning by way of the existing mount-
  smoke test plus the gettext-extractor: the literal is now a
  compile-time argument and shows up under `mix gettext.extract`.

- ~~**C12 #1/#3 [MEDIUM]** No catch-all `handle_info/2` in any of
  the 3 LVs~~ — added a defensive catch-all to `hello_live.ex`,
  `events_live.ex`, `components_live.ex`. Each clause logs at
  `:debug` (per workspace sync precedent at AGENTS.md:678-680) so
  it never spams in prod but stays grep-able. Pinned with one new
  test per LV ("handle_info catch-all swallows unknown messages")
  that `send/2`s `:unknown_pubsub_event` and a tagged tuple to
  `view.pid` and asserts `render(view)` still returns the
  page-title HTML — would crash with `FunctionClauseError` if the
  catch-all regresses.

  `events_live.ex` also gained `require Logger` (was previously
  unused); `hello_live.ex` and `components_live.ex` already had it.

### Skipped (with rationale)

- **C12 #2 [MEDIUM]** Ungettext'd showcase labels in
  `components_live.ex` (e.g. `<.showcase_section title="Icons">`,
  "Badges", "Buttons", "Alerts", section titles for ~22 sections):
  these are component pattern names in a teaching showcase, not
  feature copy. The original sweep deliberately scoped i18n to
  feature copy and left demo-content English alone. Wrapping them
  doesn't add user value because they describe components by their
  technical names. Keep as-is unless Max overrides.

- **Agent #2 [HIGH]** "Demo button `:error` branch should call
  `PhoenixKit.Activity.log` with `db_pending: true`": this is a
  category mismatch. For modules with a primary write (locations,
  catalogue), `:error`-branch activity logging captures user
  intent even when the cache write fails. For hello_world the
  activity log IS the entire operation — there is no out-of-band
  primary write to audit. Calling `Activity.log` from the
  recovery path of a failing `Activity.log` is circular. The
  current behaviour (Logger.warning + user-visible flash) already
  captures the failure.

- **Agent #1 [LOW]** "Narrow `rescue` clauses in `events_live.ex`
  load_filter_options / load_next_page": both are defensive UI
  fall-backs — when `PhoenixKit.Activity` raises (table missing,
  DB down) the page degrades to "no entries" rather than 500.
  Adding a `:debug` log is a soft improvement; pinning would
  require stubbing Activity, which the workspace coverage push
  pattern explicitly rejects in favour of zero new test deps.
  Leave silent.

- **Agent #3 [LOW]** "Missing `@spec` on
  `PhoenixKit.Module` callbacks in `phoenix_kit_hello_world.ex`":
  the behaviour declares each callback's contract; `@spec` here
  would duplicate what `@impl PhoenixKit.Module` already pins.
  Original sweep didn't add `@spec` to callbacks for the same
  reason. Skip.

- **Agent #3 [LOW]** "`paths.ex` missing `@spec`": false positive
  — every public fn in `paths.ex` already carries `@spec`
  (lines 20, 24, 28). Verified by grep.

- **Agent #3 [LOW]** "Commented-out `def`s in `routes.ex`": this
  file is an intentional *template scaffold* — its first three
  lines call this out explicitly ("Template scaffold — uncomment
  the stubs below when your module needs multiple admin pages or
  public routes"). The whole point of the commented `def`s is
  pedagogical: they show users *where* to put their routes when
  they need them. Same shape as the "Other optional callbacks
  you can override (shown with their defaults)" comment block at
  `phoenix_kit_hello_world.ex:253-266`. Keep.

- **Agent #1 [LOW]** "`phx-disable-with` on Clear filters
  button": UI-state-only button (just clears the filter form, no
  DB write, no async work). Per workspace AGENTS.md C5:
  "UI-state-only buttons (modal_close, switch_view) don't need
  it." Skip.

## Files touched (Batch 2)

| File                                                                                   | Change                                                                       |
|----------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `lib/phoenix_kit_hello_world/web/hello_live.ex`                                        | 32 gettext wrap call sites (~22 user-facing spans) on card titles, dt labels, next-steps copy; handle_info catch-all |
| `lib/phoenix_kit_hello_world/web/events_live.ex`                                       | gettext wrap on `title="View details"`; `require Logger`; handle_info catch-all   |
| `lib/phoenix_kit_hello_world/web/components_live.ex`                                   | handle_info catch-all                                                        |
| `test/phoenix_kit_hello_world/web/hello_live_test.exs`                                 | +2 tests: dt-label regex sweep, handle_info catch-all smoke                  |
| `test/phoenix_kit_hello_world/web/events_live_test.exs`                                | +2 tests: title-wrap smoke, handle_info catch-all smoke                      |
| `test/phoenix_kit_hello_world/web/components_live_test.exs`                            | +1 test: handle_info catch-all smoke                                         |
| `dev_docs/pull_requests/2026/14-quality-sweep/FOLLOW_UP.md`                            | this file                                                                    |

## Verification

- `mix precommit` clean (compile + format + credo --strict + dialyzer 0 errors).
- 50 → 55 tests (+5 Batch 2 deltas), 0 failures.
- 10/10 stable runs (`for i in $(seq 1 10); do mix test --seed 0; done`)
  consistently 2.4–2.6s.
- Stale-ref grep clean: zero IO.inspect/IO.puts/IO.warn, zero TODO/FIXME/HACK/XXX,
  zero raw `{:error, "string"}` shapes, zero String.capitalize, zero Task.start
  (verified `Task\.start[^_]` returns no matches).
- The "commented-out def" matches in `phoenix_kit_hello_world.ex:247,256-263`
  and `routes.ex:71-117` are intentional template-doc scaffolds (each block
  is preceded by a moduledoc/section heading explaining its pedagogical role).

## Pre-existing log noise (not introduced by this sweep)

`mix test` emits `[error] Failed to query setting hello_world_enabled:
%DBConnection.OwnershipError{...}` from core's
`PhoenixKit.Settings.get_boolean_setting/2` when a non-sandbox-allowed
process queries during a test. Documented in workspace AGENTS.md:1075-1076
as upstream noise; suppressing it lives in core. Same noise on PR #14's
original sweep — not introduced here.

A `[warning] [ComponentsLive] reorder_items rejected: expected 6 ids,
got 2` line is intentional — it's the `reorder_items` validation logging
the rejected client payload during the "rejects mismatched id list" test.

## Open

None. Every C12 / C12.5 finding is either fixed in Batch 2 or surfaced
above with rationale. Batch 3 (fix-everything) would close the
"showcase labels" item (mass i18n wrap on `components_live.ex`); Max's
call.
