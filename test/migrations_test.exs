defmodule PhoenixKitHelloWorld.MigrationsTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Guards the module-owned migration contract — the four functions
  `mix phoenix_kit.update` calls on a `migration_module/0`.

  Copy this file with the coordinator: it is what catches a coordinator that
  compiles but can't actually be driven by the host tooling. The database
  side is asserted in `PhoenixKitHelloWorld.MigrationsIntegrationTest` below.
  """

  alias PhoenixKitHelloWorld.Migrations

  test "the module returns its coordinator from migration_module/0" do
    assert PhoenixKitHelloWorld.migration_module() == Migrations
  end

  test "exports every function mix phoenix_kit.update calls" do
    Code.ensure_loaded!(Migrations)

    assert function_exported?(Migrations, :current_version, 0)
    assert function_exported?(Migrations, :migrated_version_runtime, 1)
    assert function_exported?(Migrations, :up, 1)
    assert function_exported?(Migrations, :down, 1)
  end

  test "current_version/0 is a positive integer" do
    assert is_integer(Migrations.current_version())
    assert Migrations.current_version() > 0
  end

  test "rejects a prefix that can't be safely interpolated into SQL" do
    assert_raise ArgumentError, fn ->
      Migrations.migrated_version(prefix: "public; DROP TABLE phoenix_kit")
    end
  end
end

defmodule PhoenixKitHelloWorld.MigrationsIntegrationTest do
  use PhoenixKitHelloWorld.DataCase, async: true

  @moduledoc """
  Asserts what the coordinator actually left in the test database.

  `test/test_helper.exs` runs `PhoenixKitHelloWorld.Migrations` through
  `Ecto.Migrator` on every boot, the same way a host app runs it via
  `mix phoenix_kit.update` — so these assertions cover the real code path,
  not a hand-built table.
  """

  alias PhoenixKitHelloWorld.Migrations

  test "the owned table exists in the target schema" do
    assert {:ok, %{rows: [[true]]}} =
             Repo.query("""
             SELECT EXISTS (
               SELECT FROM information_schema.tables
               WHERE table_name = 'phoenix_kit_hello_world_items'
               AND table_schema = 'public'
             )
             """)
  end

  test "the version comment matches current_version/0" do
    assert {:ok, %{rows: [[comment]]}} =
             Repo.query("""
             SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
             FROM pg_class
             LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
             WHERE pg_class.relname = 'phoenix_kit_hello_world_items'
             AND pg_namespace.nspname = 'public'
             """)

    assert comment == to_string(Migrations.current_version())
  end

  test "migrated_version_runtime/1 reports the installed version" do
    assert Migrations.migrated_version_runtime(prefix: "public") ==
             Migrations.current_version()
  end

  test "migrated_version_runtime/1 reports 0 for a schema with no install" do
    assert Migrations.migrated_version_runtime(prefix: "no_such_schema") == 0
  end
end
