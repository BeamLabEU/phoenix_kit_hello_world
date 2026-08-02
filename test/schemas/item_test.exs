defmodule PhoenixKitHelloWorld.Schemas.ItemTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Changeset tests for the template schema — pure, no database.
  """

  alias PhoenixKitHelloWorld.Schemas.Item

  test "a name is required" do
    changeset = Item.changeset(%Item{}, %{})

    refute changeset.valid?
    assert %{name: ["can't be blank"]} = errors_on(changeset)
  end

  test "status must be one of the known values" do
    changeset = Item.changeset(%Item{}, %{name: "Demo", status: "nope"})

    refute changeset.valid?
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "casts only the allowlisted fields" do
    changeset =
      Item.changeset(%Item{}, %{name: "Demo", data: %{"k" => "v"}, uuid: "not-a-uuid"})

    assert changeset.valid?
    assert changeset.changes == %{name: "Demo", data: %{"k" => "v"}}
  end

  test "statuses/0 lists the accepted statuses" do
    assert "active" in Item.statuses()
    assert "deleted" in Item.statuses()
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

defmodule PhoenixKitHelloWorld.Schemas.ItemIntegrationTest do
  use PhoenixKitHelloWorld.DataCase, async: true

  @moduledoc """
  Round-trips the schema against the table its own migration created —
  the end-to-end proof that the module-owned DDL and the schema agree.
  """

  alias PhoenixKitHelloWorld.Schemas.Item

  test "inserts and reads back an item" do
    assert {:ok, item} =
             %Item{}
             |> Item.changeset(%{name: "Demo", data: %{"greeting" => "hello"}})
             |> Repo.insert()

    assert item.status == "active"
    assert is_binary(item.uuid)
    assert %DateTime{} = item.inserted_at

    reloaded = Repo.get!(Item, item.uuid)
    assert reloaded.name == "Demo"
    assert reloaded.data == %{"greeting" => "hello"}
  end

  test "the migration made name NOT NULL, not just the changeset" do
    assert {:error, %Postgrex.Error{postgres: %{code: :not_null_violation}}} =
             Repo.query("""
             INSERT INTO phoenix_kit_hello_world_items (inserted_at, updated_at)
             VALUES (now(), now())
             """)
  end
end
