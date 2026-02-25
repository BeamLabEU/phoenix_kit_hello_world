defmodule PhoenixKitHelloWorld.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mdon/phoenix_kit_hello_world"

  def project do
    [
      app: :phoenix_kit_hello_world,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description:
        "Hello World demo module for PhoenixKit — use as a template for your own plugins",
      package: package(),

      # Docs
      name: "PhoenixKitHelloWorld",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # PhoenixKit provides the Module behaviour and Settings API.
      # For a published hex package, use: {:phoenix_kit, "~> 1.7"}
      {:phoenix_kit, path: "../phoenix_kit"},

      # LiveView is needed for the admin page.
      {:phoenix_live_view, "~> 1.0"},

      # Optional: add ex_doc for generating documentation
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "PhoenixKitHelloWorld",
      source_ref: "v#{@version}"
    ]
  end
end
