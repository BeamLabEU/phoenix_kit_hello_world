# Example Ecto schema for a PhoenixKit module — deliberately ALL comments.
#
# hello_world has no database tables of its own, so this file compiles to
# nothing. It exists because hello_world is the canonical module template:
# when your module DOES need a table, copy this shape (and see the live
# references at the bottom).
#
# The conventions below are load-bearing — each one exists because a real
# module got it wrong once:
#
#   1. `use PhoenixKit.SchemaPrefix` (core >= 1.7.189) right after
#      `use Ecto.Schema`. Core supports installing into a named Postgres
#      schema (`mix phoenix_kit.install --prefix "auth"`); the migrations
#      create your module's tables INSIDE that schema. This line makes your
#      queries target it too. Without it, your schema resolves tables via
#      the connection's search_path — which works on default public installs
#      and silently breaks on prefixed ones. With no prefix configured it
#      compiles to nil (zero behavior change), so there is no reason to
#      omit it. Copy test/schema_prefix_conformance_test.exs along with it —
#      the test scans lib/ and fails if a table-backed schema misses the line.
#
#   2. UUIDv7 primary keys, named `uuid` (not `id` — integer ids are the
#      deprecated legacy convention in this ecosystem).
#
#   3. Table name prefixed `phoenix_kit_<module_key>_` (see "Database
#      conventions" in the README — generic names collide with other
#      modules and the parent app).
#
#   4. `timestamps(type: :utc_datetime)` — the workspace standardized on
#      timestamptz columns (core migration V58).
#
# defmodule PhoenixKitHelloWorld.Schemas.Item do
#   @moduledoc """
#   One demo item. Tables are created by the module's versioned
#   migrations (see `migration_module/0` + the README's "Versioned
#   migrations" section), never by the schema.
#   """
#
#   use Ecto.Schema
#   use PhoenixKit.SchemaPrefix
#   import Ecto.Changeset
#
#   @primary_key {:uuid, UUIDv7, autogenerate: true}
#   @foreign_key_type UUIDv7
#
#   schema "phoenix_kit_hello_world_items" do
#     field :name, :string
#     field :status, :string, default: "active"
#     field :data, :map, default: %{}
#
#     timestamps(type: :utc_datetime)
#   end
#
#   @doc false
#   def changeset(item, attrs) do
#     item
#     # Always cast an explicit allowlist — never all fields.
#     |> cast(attrs, [:name, :status, :data])
#     |> validate_required([:name])
#     |> validate_inclusion(:status, ~w(active archived deleted))
#   end
# end
#
# Notes for real modules:
#
#   * Soft-delete is a sentinel value on the existing `status` string column
#     ("deleted" or "trashed" depending on your lifecycle) — never a
#     `deleted_at` timestamp column. See the workspace soft-delete
#     convention in phoenix_kit_entities/lib/phoenix_kit_entities/entity_data.ex.
#   * Smallest end-to-end live reference (schemas + context + Errors +
#     activity logging): phoenix_kit_locations.
#   * Migrations live in core's versioned chain for first-party modules, or
#     in your own migration coordinator for standalone ones — either way,
#     new migration SQL must stay prefix-safe (bare index names on CREATE,
#     schema-anchored existence checks; see core AGENTS.md "Prefix-safe
#     migrations").
