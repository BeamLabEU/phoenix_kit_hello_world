defmodule PhoenixKitHelloWorld.Migrations do
  @moduledoc """
  Versioned migration coordinator for `phoenix_kit_hello_world` — the module
  returned from `PhoenixKitHelloWorld.migration_module/0`.

  **This file is the template's reference implementation of module-owned
  migrations.** A PhoenixKit module ships the DDL for the tables it owns in
  its OWN repo — not as a new `Vxxx` in core `phoenix_kit`'s migration chain.
  Core's chain stays about core's tables; your module's schema ships and
  versions with your module. Copy this file, rename the module and the table,
  and you have the whole contract.

  ## The contract

  `mix phoenix_kit.update` (run in the host app) discovers every registered
  module that returns a non-nil `migration_module/0` and, for each one, calls:

    * `current_version/0` — the version the shipped code expects
    * `migrated_version_runtime/1` — the version the host's database is at
    * `up/1` / `down/1` — from a host migration file it generates when
      those two differ, e.g.

          def up, do: PhoenixKitHelloWorld.Migrations.up(prefix: "public", version: 1)
          def down, do: PhoenixKitHelloWorld.Migrations.down(prefix: "public", version: 0)

  So the host installs and upgrades this module's table by running
  `mix phoenix_kit.update` — never by hand-writing a migration — and the
  generated migration honors the host's `--prefix` (named-schema installs).

  ## Version tracking

  The installed version lives in a `COMMENT ON TABLE` on
  `phoenix_kit_hello_world_items` (the same mechanism core uses on its own
  `phoenix_kit` table). A boolean "does the table exist?" would not be
  enough: it can't tell "not installed" apart from "installed at V1", which
  is exactly what a future V2 needs to know.

  Versions:

    * `0` — table absent (not installed)
    * `1` — `phoenix_kit_hello_world_items`, UUIDv7 primary key

  ## Adding V2

  Version steps are **immutable once shipped** — a host that already ran V1
  will never run it again, so editing `up_v1/1` changes nothing for them and
  silently forks fresh installs from upgraded ones. To change the schema:

    1. Add `up_v2/1` + `down_v2/1` (use `alter table`, `add_if_not_exists`).
    2. Add the `apply_step(:up, 2, prefix)` / `apply_step(:down, 2, prefix)`
       clauses.
    3. Bump `@current_version` to `2`.
    4. Update the schema module and the version list above.

  Fresh installs then run V1 → V2 in order; hosts at V1 run only V2.

  ## Prefix safety

  Every statement passes `prefix:` through, index names stay bare (Postgres
  scopes an index to its table's schema, and rejects a qualified name on
  `CREATE INDEX`), and existence checks are anchored to the target schema.
  That is what makes a `--prefix "hello"` install land entirely inside that
  schema instead of leaking into `public`.
  """

  use Ecto.Migration

  alias PhoenixKit.Migrations.Postgres.Helpers

  @initial_version 1
  @current_version 1
  @default_prefix "public"
  @version_table "phoenix_kit_hello_world_items"

  @typedoc """
  Migration options: `:prefix` and `:version`.

  The generated host migration passes a keyword list; the internal helpers
  normalize it to a map and pass that back through the same public functions,
  so both shapes are accepted.
  """
  @type opts :: keyword() | map()

  @doc "The version this code expects the schema to be at."
  @spec current_version() :: pos_integer()
  def current_version, do: @current_version

  @doc """
  Runs every step up to (and including) the target version.

  Migration-context only — the DDL is queued through `Ecto.Migration`.
  """
  @spec up(opts()) :: :ok
  def up(opts \\ []) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 -> change(@initial_version..opts.version, :up, opts)
      initial < opts.version -> change((initial + 1)..opts.version, :up, opts)
      true -> :ok
    end

    :ok
  end

  @doc """
  Rolls back down to the target version (default `0` — everything).

  Migration-context only.
  """
  @spec down(opts()) :: :ok
  def down(opts \\ []) do
    opts = with_defaults(opts, 0)
    current = migrated_version(opts)
    target = Map.get(opts, :version, 0)

    if current > target, do: change(current..(target + 1)//-1, :down, opts)

    :ok
  end

  @doc """
  The version currently installed in the database (`0` when the table is
  absent). Migration-context only — reads via `Ecto.Migration.repo/0`.
  """
  @spec migrated_version(opts()) :: non_neg_integer()
  def migrated_version(opts \\ []) do
    opts = with_defaults(opts, @initial_version)
    read_version(repo(), opts.escaped_prefix)
  end

  @doc """
  Runtime-safe version of `migrated_version/1` — reads through PhoenixKit's
  configured repo instead of the `Ecto.Migration` `repo/0` helper, so it can
  be called outside a migration (this is the one `mix phoenix_kit.update`
  calls). Returns `0` when the database can't be reached at all.
  """
  @spec migrated_version_runtime(opts()) :: non_neg_integer()
  def migrated_version_runtime(opts \\ []) do
    opts = with_defaults(opts, @initial_version)
    read_version(PhoenixKit.RepoHelper.repo(), opts.escaped_prefix)
  rescue
    _ -> 0
  end

  # ── v1 ────────────────────────────────────────────────────────────────────

  defp up_v1(prefix) do
    # `uuid_generate_v7()` normally arrives with core's V40, but a module
    # can't assume the host ran core's chain first — this creates it inside
    # the install's schema when it's missing, and is a no-op otherwise.
    Helpers.ensure_uuid_v7_function(prefix)

    create_if_not_exists table(:phoenix_kit_hello_world_items,
                           primary_key: false,
                           prefix: prefix
                         ) do
      add(:uuid, :uuid,
        primary_key: true,
        null: false,
        default: fragment(Helpers.uuid_v7_call(prefix))
      )

      add(:name, :string, null: false)
      # Soft-delete is a sentinel on `status` ("deleted"/"trashed"), never a
      # `deleted_at` column — the workspace convention.
      add(:status, :string, size: 20, null: false, default: "active")
      add(:data, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    # Bare index name — `CREATE INDEX schema.name` is a syntax error in
    # Postgres; the index is scoped to its table's schema automatically.
    create_if_not_exists(index(:phoenix_kit_hello_world_items, [:status], prefix: prefix))
  end

  defp down_v1(prefix) do
    drop_if_exists(table(:phoenix_kit_hello_world_items, prefix: prefix))
  end

  # ── internals ─────────────────────────────────────────────────────────────

  defp change(range, direction, opts) do
    Enum.each(range, &apply_step(direction, &1, opts.prefix))

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, max(Enum.min(range) - 1, 0))
    end
  end

  defp apply_step(:up, 1, prefix), do: up_v1(prefix)
  defp apply_step(:down, 1, prefix), do: down_v1(prefix)

  defp apply_step(direction, version, _prefix) do
    raise ArgumentError,
          "no #{direction} step defined for phoenix_kit_hello_world schema version #{version}"
  end

  # Version 0 means the table is gone — there is nothing left to comment on.
  defp record_version(_opts, 0), do: :ok

  defp record_version(%{prefix: prefix}, version) do
    execute("COMMENT ON TABLE #{Helpers.qualify_table(@version_table, prefix)} IS '#{version}'")
  end

  defp with_defaults(opts, version) do
    opts = Enum.into(opts, %{prefix: @default_prefix, version: version})

    # The prefix is interpolated into raw SQL below; reject anything that
    # isn't a plain lower-case identifier before it gets there.
    Helpers.validate_prefix!(opts.prefix)

    opts
    |> Map.put(:quoted_prefix, inspect(opts.prefix))
    |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "\\'"))
  end

  defp read_version(repo, escaped_prefix) do
    table_exists_query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_name = '#{@version_table}'
      AND table_schema = '#{escaped_prefix}'
    )
    """

    case repo.query(table_exists_query, [], log: false) do
      {:ok, %{rows: [[true]]}} -> read_comment_version(repo, escaped_prefix)
      _ -> 0
    end
  end

  defp read_comment_version(repo, escaped_prefix) do
    version_query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = '#{@version_table}'
    AND pg_namespace.nspname = '#{escaped_prefix}'
    """

    case repo.query(version_query, [], log: false) do
      # Table exists but carries no version comment: it was created by V1
      # before version tracking could have written anything else.
      {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
      _ -> 1
    end
  end
end
