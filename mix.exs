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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["format --check-formatted", "credo --strict", "test"]
    ]
  end
end
