defmodule PhoenixKitHelloWorld.Schemas.Item do
  @moduledoc """
  One demo item — the template's reference Ecto schema.

  The table behind it (`phoenix_kit_hello_world_items`) is created by this
  module's OWN versioned migrations
  (`PhoenixKitHelloWorld.Migrations`, returned from
  `PhoenixKitHelloWorld.migration_module/0`), never by the schema and never
  by a migration added to core `phoenix_kit`. A schema and its DDL ship
  together, in the same repo, versioned with the same package.

  hello_world has no context module and no business logic around this
  schema on purpose — it exists so the module-owned migration chain is a
  real, tested, copyable thing rather than a comment block. When you build
  a real module, add a context (see `phoenix_kit_locations` for the
  smallest end-to-end reference) and keep every convention below.

  ## Conventions (each one exists because a real module got it wrong once)

    1. `use PhoenixKit.SchemaPrefix` (core >= 1.7.189) right after
       `use Ecto.Schema`. Core supports installing into a named Postgres
       schema (`mix phoenix_kit.install --prefix "auth"`) and the migrations
       create your module's tables INSIDE that schema. This line makes your
       queries target it too. Without it, the schema resolves tables via the
       connection's `search_path` — which works on default public installs
       and silently breaks on prefixed ones. With no prefix configured it
       compiles to `nil` (zero behavior change), so there is no reason to
       omit it. `test/schema_prefix_conformance_test.exs` scans `lib/` and
       fails when a table-backed schema misses the line — copy it too.

    2. UUIDv7 primary keys, named `uuid` (not `id` — integer ids are the
       deprecated legacy convention in this ecosystem).

    3. Table name prefixed `phoenix_kit_<module_key>_` (see "Database
       conventions" in the README — generic names collide with other
       modules and with the parent app).

    4. `timestamps/1` type matches the migration's. This schema and
       `up_v1/1` both say `:utc_datetime_usec`; a schema declaring
       `:utc_datetime` against `timestamptz(6)` columns silently truncates
       on write.

    5. Soft-delete is a sentinel value on the existing `status` string
       column ("deleted" or "trashed", depending on your lifecycle) — never
       a `deleted_at` timestamp column. See the workspace convention in
       `phoenix_kit_entities/lib/phoenix_kit_entities/entity_data.ex`.
  """

  use Ecto.Schema
  use PhoenixKit.SchemaPrefix

  import Ecto.Changeset

  @primary_key {:uuid, UUIDv7, autogenerate: true}
  @foreign_key_type UUIDv7

  @statuses ~w(active archived deleted)

  schema "phoenix_kit_hello_world_items" do
    field(:name, :string)
    field(:status, :string, default: "active")
    field(:data, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @typedoc "A demo item row."
  @type t :: %__MODULE__{}

  @doc "The statuses `changeset/2` accepts."
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc """
  Builds a changeset for creating or updating an item.

  Note the explicit `cast/3` allowlist — never cast every field. Real
  modules usually grow several named changesets (`create_changeset/2`,
  `admin_changeset/2`, ...) rather than one changeset doing every job.
  """
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :status, :data])
    |> validate_required([:name])
    |> validate_inclusion(:status, @statuses)
  end
end
