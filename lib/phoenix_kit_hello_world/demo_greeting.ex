defmodule PhoenixKitHelloWorld.DemoGreeting do
  @moduledoc """
  The greeting the Overview page lets you edit — the record behind the
  "log an update with what changed" demo.

  It is an embedded schema with no table (hello_world keeps no data of its
  own): the page holds the current greeting in an assign, so an edit lasts
  until the page is reloaded. What the demo shows is the logging, which is
  the same for a real table-backed record: build the changeset, save it, and
  pass that changeset to `PhoenixKit.Activity.log/3` as `changes:` — core
  records each field that moved as `%{"from" => old, "to" => new}` under
  the entry's `metadata["changes"]`, and the Activity pages show it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @tones ~w(casual formal)

  @primary_key false
  embedded_schema do
    field(:text, :string, default: "Hello, world!")
    field(:tone, :string, default: "casual")
  end

  @type t :: %__MODULE__{text: String.t(), tone: String.t()}

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
end
