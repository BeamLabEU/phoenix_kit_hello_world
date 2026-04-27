defmodule PhoenixKitHelloWorld.Test.Repo.Migrations.SetupPhoenixKit do
  use Ecto.Migration

  @moduledoc """
  Test-only setup. Recreates the minimal slice of `phoenix_kit` core's
  schema that hello_world's tests touch:

  - `uuid_generate_v7()` PL/pgSQL function (normally created by core's
    V40 migration)
  - `phoenix_kit_settings` — only needed if a test exercises the
    settings API directly. Hello World's `enabled?/0` rescues, so most
    tests don't need it; included here so future tests can opt in.
  - `phoenix_kit_activities` — required for activity log assertions.

  Hello World ships **no application tables** of its own. Modules with
  schemas (locations, catalogue, etc.) add their tables here too.
  """

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    execute("""
    CREATE OR REPLACE FUNCTION uuid_generate_v7()
    RETURNS uuid AS $$
    DECLARE
      unix_ts_ms bytea;
      uuid_bytes bytea;
    BEGIN
      unix_ts_ms := substring(int8send(floor(extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3);
      uuid_bytes := unix_ts_ms || gen_random_bytes(10);
      uuid_bytes := set_byte(uuid_bytes, 6, (get_byte(uuid_bytes, 6) & 15) | 112);
      uuid_bytes := set_byte(uuid_bytes, 8, (get_byte(uuid_bytes, 8) & 63) | 128);
      RETURN encode(uuid_bytes, 'hex')::uuid;
    END
    $$ LANGUAGE plpgsql VOLATILE;
    """)

    # Settings table — must match `PhoenixKit.Settings.Setting` schema
    # (uuid PK, key, value, value_json, module, date_added, date_updated)
    # so reads issued by `enabled?/0` don't poison the sandbox transaction
    # with a column-mismatch error.
    create_if_not_exists table(:phoenix_kit_settings, primary_key: false) do
      add(:uuid, :uuid, primary_key: true, default: fragment("uuid_generate_v7()"))
      add(:key, :string, null: false, size: 255)
      add(:value, :string)
      add(:value_json, :map)
      add(:module, :string, size: 50)
      add(:date_added, :utc_datetime_usec, null: false, default: fragment("NOW()"))
      add(:date_updated, :utc_datetime_usec, null: false, default: fragment("NOW()"))
    end

    create_if_not_exists(unique_index(:phoenix_kit_settings, [:key]))

    # Activity feed table (normally created by PhoenixKit V90 migration).
    # Uses binary_id (not uuid_generate_v7()) because the Ecto schema
    # supplies the UUIDv7 — the DB column only needs to hold 16 bytes.
    create_if_not_exists table(:phoenix_kit_activities, primary_key: false) do
      add(:uuid, :binary_id, primary_key: true)
      add(:action, :string, null: false, size: 100)
      add(:module, :string, size: 50)
      add(:mode, :string, size: 20)
      add(:actor_uuid, :binary_id)
      add(:resource_type, :string, size: 50)
      add(:resource_uuid, :binary_id)
      add(:target_uuid, :binary_id)
      add(:metadata, :map, default: %{})
      add(:inserted_at, :utc_datetime, null: false, default: fragment("now()"))
    end

    create_if_not_exists(index(:phoenix_kit_activities, [:module]))
    create_if_not_exists(index(:phoenix_kit_activities, [:action]))
    create_if_not_exists(index(:phoenix_kit_activities, [:actor_uuid]))
    create_if_not_exists(index(:phoenix_kit_activities, [:inserted_at]))
  end

  def down do
    drop_if_exists(table(:phoenix_kit_activities))
    drop_if_exists(table(:phoenix_kit_settings))
  end
end
