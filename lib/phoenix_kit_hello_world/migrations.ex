# Example versioned migration coordinator for a PhoenixKit module —
# deliberately ALL comments.
#
# hello_world is the canonical module TEMPLATE, so it owns no database
# tables: a demo module has no business creating a table in every host that
# installs it. This file therefore compiles to nothing. It exists because
# when your module DOES need a table, this is the shape to copy — and
# because the policy it encodes is easy to get wrong:
#
#   **A module ships the DDL for its own tables.** The migrations live in
#   YOUR repo and version with YOUR package. They are NOT added as a new
#   `Vxxx` to core phoenix_kit's migration chain — that would couple your
#   schema to a core release and grow the core package for hosts that never
#   install your module.
#
# ## The contract
#
# `mix phoenix_kit.update` (run in the host app) scans beam files for
# registered modules, calls `migration_module/0` on each, and for every
# module whose database is behind:
#
#   * reads `migrated_version_runtime(prefix: prefix)` — what the host has
#   * reads `current_version/0` — what the shipped code needs
#   * writes a migration into the host's `priv/repo/migrations/` that calls
#     back into your `up/1` (and `down/1` for rollback)
#   * runs `mix ecto.migrate`
#
# So the host never hand-writes migration SQL for your module, there is no
# install task to ship, and the generated migration honors the host's
# `--prefix` (named-schema installs). Registering it is one line in your
# module:
#
#     @impl PhoenixKit.Module
#     def migration_module, do: MyModule.Migrations
#
# ## Live references
#
# Two published modules implement exactly this file: phoenix_kit_boards
# (single table) and phoenix_kit_web_analytics (two tables plus indexes).
# Read those when you want a version that actually runs.
#
# defmodule MyModule.Migrations do
#   @moduledoc """
#   Versioned migration coordinator for `my_module`.
#
#   Versions:
#
#     * `0` — table absent (not installed)
#     * `1` — `phoenix_kit_my_module_items`, UUIDv7 primary key
#   """
#
#   use Ecto.Migration
#
#   alias PhoenixKit.Migrations.Postgres.Helpers
#
#   @initial_version 1
#   @current_version 1
#   @default_prefix "public"
#   # The version marker lives in a COMMENT ON TABLE on this table. A
#   # boolean "does the table exist" would not do: it can't tell "not
#   # installed" apart from "installed at V1", which is exactly what a
#   # future V2 needs to know.
#   @version_table "phoenix_kit_my_module_items"
#
#   @doc "The version this code expects the schema to be at."
#   def current_version, do: @current_version
#
#   @doc "Run every step up to (and including) the target version."
#   def up(opts \\ []) do
#     opts = with_defaults(opts, @current_version)
#     initial = migrated_version(opts)
#
#     cond do
#       initial == 0 -> change(@initial_version..opts.version, :up, opts)
#       initial < opts.version -> change((initial + 1)..opts.version, :up, opts)
#       true -> :ok
#     end
#
#     :ok
#   end
#
#   @doc "Roll back down to the target version (default 0 — everything)."
#   def down(opts \\ []) do
#     opts = with_defaults(opts, 0)
#     current = migrated_version(opts)
#     target = Map.get(opts, :version, 0)
#
#     if current > target, do: change(current..(target + 1)//-1, :down, opts)
#
#     :ok
#   end
#
#   # Migration context — reads through the `Ecto.Migration` repo() helper.
#   def migrated_version(opts \\ []) do
#     opts = with_defaults(opts, @initial_version)
#     read_version(repo(), opts.escaped_prefix)
#   end
#
#   # Runtime context — this is the one `mix phoenix_kit.update` calls, from
#   # a Mix task with no migrator running, so it goes through PhoenixKit's
#   # configured repo instead. (`PhoenixKit.Config.get_repo/0` does NOT
#   # exist — older copies of this snippet had it wrong.) Returns 0 when the
#   # database can't be reached at all.
#   def migrated_version_runtime(opts \\ []) do
#     opts = with_defaults(opts, @initial_version)
#     read_version(PhoenixKit.RepoHelper.repo(), opts.escaped_prefix)
#   rescue
#     _ -> 0
#   end
#
#   # ── v1 ──────────────────────────────────────────────────────────────
#
#   defp up_v1(prefix) do
#     # Don't assume core's chain ran first — a no-op when the function
#     # already exists, and creates it inside `prefix` when it doesn't.
#     Helpers.ensure_uuid_v7_function(prefix)
#
#     create_if_not_exists table(:phoenix_kit_my_module_items,
#                            primary_key: false,
#                            prefix: prefix
#                          ) do
#       add(:uuid, :uuid,
#         primary_key: true,
#         null: false,
#         default: fragment(Helpers.uuid_v7_call(prefix))
#       )
#
#       add(:name, :string, null: false)
#       add(:status, :string, size: 20, null: false, default: "active")
#       add(:data, :map, null: false, default: %{})
#
#       timestamps(type: :utc_datetime_usec)
#     end
#
#     # Bare index name — `CREATE INDEX schema.name` is a syntax error in
#     # Postgres; an index is scoped to its table's schema automatically.
#     create_if_not_exists(index(:phoenix_kit_my_module_items, [:status], prefix: prefix))
#   end
#
#   defp down_v1(prefix) do
#     drop_if_exists(table(:phoenix_kit_my_module_items, prefix: prefix))
#   end
#
#   # ── internals ───────────────────────────────────────────────────────
#
#   defp change(range, direction, opts) do
#     Enum.each(range, &apply_step(direction, &1, opts.prefix))
#
#     case direction do
#       :up -> record_version(opts, Enum.max(range))
#       :down -> record_version(opts, max(Enum.min(range) - 1, 0))
#     end
#   end
#
#   defp apply_step(:up, 1, prefix), do: up_v1(prefix)
#   defp apply_step(:down, 1, prefix), do: down_v1(prefix)
#
#   defp apply_step(direction, version, _prefix) do
#     raise ArgumentError, "no #{direction} step defined for schema version #{version}"
#   end
#
#   # Version 0 means the table is gone — nothing left to comment on.
#   defp record_version(_opts, 0), do: :ok
#
#   defp record_version(%{prefix: prefix}, version) do
#     execute("COMMENT ON TABLE #{Helpers.qualify_table(@version_table, prefix)} IS '#{version}'")
#   end
#
#   defp with_defaults(opts, version) do
#     opts = Enum.into(opts, %{prefix: @default_prefix, version: version})
#
#     # The prefix is interpolated into raw SQL below.
#     Helpers.validate_prefix!(opts.prefix)
#
#     opts
#     |> Map.put(:quoted_prefix, inspect(opts.prefix))
#     |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "\\'"))
#   end
#
#   defp read_version(repo, escaped_prefix) do
#     table_exists_query = """
#     SELECT EXISTS (
#       SELECT FROM information_schema.tables
#       WHERE table_name = '#{@version_table}'
#       AND table_schema = '#{escaped_prefix}'
#     )
#     """
#
#     case repo.query(table_exists_query, [], log: false) do
#       {:ok, %{rows: [[true]]}} -> read_comment_version(repo, escaped_prefix)
#       _ -> 0
#     end
#   end
#
#   defp read_comment_version(repo, escaped_prefix) do
#     version_query = """
#     SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
#     FROM pg_class
#     LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
#     WHERE pg_class.relname = '#{@version_table}'
#     AND pg_namespace.nspname = '#{escaped_prefix}'
#     """
#
#     case repo.query(version_query, [], log: false) do
#       {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
#       # Table exists with no comment: created by V1, before anything else
#       # could have been written.
#       _ -> 1
#     end
#   end
# end
#
# Notes for real modules:
#
#   * Version steps are IMMUTABLE once shipped. A host already at V1 never
#     re-runs V1, so editing `up_v1/1` only forks fresh installs from
#     upgraded ones. Add `up_v2/1` + its `apply_step/3` clauses and bump
#     `@current_version`.
#
#   * Stay prefix-safe. Pass `prefix:` to every table/index/alter, keep
#     index NAMES bare on CREATE, and anchor existence checks to the target
#     schema. `PhoenixKit.Migrations.Postgres.Helpers` has the pieces:
#     `qualify_table/2`, `uuid_v7_call/1`, `ensure_uuid_v7_function/1`,
#     `validate_prefix!/1`.
#
#   * Test it. `up/1` uses `Ecto.Migration` macros, so it can't be called
#     directly — wrap it in a static `use Ecto.Migration` module and run
#     that through `Ecto.Migrator.up/4` in `test/test_helper.exs`, after
#     `PhoenixKit.Migration.ensure_current/2`. Pass
#     `:os.system_time(:microsecond)` as the version, never a fixed `0`:
#     once `0` is in `schema_migrations` the wrapper is never invoked
#     again, and versions you ship later silently stop applying. The
#     README's "Testing your migration" section has the full snippet.
