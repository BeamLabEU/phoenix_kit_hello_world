defmodule PhoenixKitHelloWorld.Test.MigrationRunner do
  @moduledoc """
  Static `Ecto.Migration` wrapper that applies this module's own versioned
  migrations to the test database.

  `PhoenixKitHelloWorld.Migrations.up/1` uses `Ecto.Migration` macros, so it
  can't be called directly — it needs a migrator process around it. In a host
  app `mix phoenix_kit.update` generates exactly this wrapper; here
  `test/test_helper.exs` runs it through `Ecto.Migrator.up/4` on every boot,
  right after core's chain (`PhoenixKit.Migration.ensure_current/2`).

  Copy this file along with the coordinator — it is how a module tests its
  own DDL without depending on a host app.
  """

  use Ecto.Migration

  def up, do: PhoenixKitHelloWorld.Migrations.up(prefix: "public")

  def down, do: PhoenixKitHelloWorld.Migrations.down(prefix: "public", version: 0)
end
