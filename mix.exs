defmodule HackerNews.MixProject do
  use Mix.Project

  def project do
    [
      app: :hacker_news,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HackerNews.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:credo, "~> 1.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:sobelow, "~> 0.11.1", only: [:dev]},
      {:mint_web_socket, "~> 0.3.0", only: [:test]}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --all-warnings --warnings-as-errors",
        "credo --strict",
        "sobelow --config",
        "dialyzer"
      ],
      test: ["test --warnings-as-errors"]
    ]
  end

  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions,
        :underspecs
      ]
    ]
  end
end
