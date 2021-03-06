defmodule OLEDVirtual.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :oled_virtual,
      version: @version,
      name: "OLEDVirtual",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/pappersverk/oled_virtual",
      homepage_url: "https://github.com/pappersverk/oled_virtual"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    OLEDVirtual is a library to mock the OLED (`oled` library) screen for local development.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oled, "~> 0.3.5"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:makeup_eex, ">= 0.1.1", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      maintainers: ["Phillipp Ohlandt"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pappersverk/oled_virtual"}
    }
  end

  defp docs do
    [
      main: "OLEDVirtual",
      source_ref: @version,
      source_url: "https://github.com/pappersverk/oled_virtual",
      extra_section: "GUIDES",
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp extras do
    [
      "CHANGELOG.md",
      "guides/virtual-display-liveview.md",
      "guides/multidisplay-and-nerves.md"
    ]
  end

  defp groups_for_extras do
    [
      Guides: ~r{guides/[^\/]+\.md}
    ]
  end
end
