# PR #45 greeting activity review

Reviewed the Overview form, Events feed, dependency update, translations, tests and copyable examples. [Pull request #45](https://github.com/BeamLabEU/phoenix_kit_hello_world/pull/45)

- **BUG - HIGH** — The form reported a successful update even though the locked PhoenixKit release ignored the `changes:` option. The default test run excluded the assertion that would catch the missing audit details. PhoenixKit 3.5.0 already accepts a field diff in activity metadata, and the Events summary reads that format.
- **BUG - MEDIUM** — The form advanced its saved greeting before the audit insert succeeded. Retrying the same edit after an insert error took the unchanged branch, leaving that edit out of the feed.
- **IMPROVEMENT - MEDIUM** — The second-save test selected the first row ordered only by timestamp. Two inserts with the same timestamp could make the result depend on database row order.
- **IMPROVEMENT - MEDIUM** — Greeting handlers reused the permission boolean calculated at mount. They should evaluate the scope currently assigned to the socket, as the moderation handler does.
- **BUG - MEDIUM** — The event handlers accepted any nested map. On a casting error, Phoenix form fields can return the original value from the submitted parameters, including values a text input cannot render.
