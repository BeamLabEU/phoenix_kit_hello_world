# PR #45 fixes

- The greeting records its two public demo fields under `metadata["changes"]` through the released logging API. The examples use the same format. The default integration suite checks both values of each changed field.
- The form advances its saved greeting after the activity insert succeeds. A failed insert keeps the submitted values visible for retry. A regression test exercises two submissions after an insert failure.
- The second-save assertion identifies the event by its recorded diff, so it works even when timestamps tie.
- The base-permission handlers check the current socket scope before validation, saving or logging a demo event.
- Both form events require string values for the two submitted fields. The existing malformed-event test covers each field and handler.

Verified with the committed Hex lock and PostgreSQL. All 247 tests passed and `mix precommit` succeeded.
