defmodule PhoenixKitHelloWorld.DemoGreeting do
  @moduledoc """
  The greeting the Overview page lets you edit — the record behind the
  "log an update with what changed" demo.

  It is an embedded schema with no table (hello_world keeps no data of its
  own): the page holds the current greeting in an assign, so an edit lasts
  until the page is reloaded. What the demo shows is the logging, which is
  the same for a real table-backed record: build the changeset, save it, and
  record the changed demo fields under the activity metadata's "changes" key.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @tones ~w(casual formal)

  # No `default:` on the fields: `cast/4` turns an empty input into the
  # field's default, so a blank greeting would silently become the default
  # instead of failing `validate_required/2`. The starting greeting is
  # `new/0` instead.
  @primary_key false
  embedded_schema do
    field(:text, :string)
    field(:tone, :string)
  end

  @type t :: %__MODULE__{text: String.t(), tone: String.t()}

  @doc "The greeting the page starts with."
  @spec new() :: t()
  def new, do: %__MODULE__{text: "Hello, world!", tone: "casual"}

  @doc "The tones the form offers."
  @spec tones() :: [String.t()]
  def tones, do: @tones

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(greeting, attrs) do
    greeting
    |> cast(attrs, [:text, :tone])
    |> validate_required([:text, :tone])
    |> validate_length(:text, max: 80)
    |> validate_inclusion(:tone, @tones)
  end

  @doc "Before and after values for the two public demo fields that changed."
  def activity_changes(changeset) do
    for {field, value} <- Map.take(changeset.changes, [:text, :tone]), into: %{} do
      {Atom.to_string(field), %{"from" => Map.fetch!(changeset.data, field), "to" => value}}
    end
  end
end
