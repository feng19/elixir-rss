defmodule ElixirRss.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_rss,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirRss.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.7"},
      {:fiet, "~> 0.3"},
      {:timex, "~> 3.6"},
      {:floki, ">= 0.27.0"},
      {:html5ever, "~> 0.8"},
      {:tencent_cloud, "~> 0.1"}
    ]
  end
end
