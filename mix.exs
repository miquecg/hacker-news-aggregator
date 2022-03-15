defmodule HackerNews.MixProject do
  use Mix.Project

  def project do
    [
      app: :hacker_news,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_local_path: "priv/plts",
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HackerNews.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:credo, "~> 1.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --all-warnings --warnings-as-errors",
        "credo --strict",
        "dialyzer"
      ],
      test: ["test --warnings-as-errors"]
    ]
  end
end
