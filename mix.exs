defmodule Blexchain.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blexchain,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]      
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Blexchain, []},
      extra_applications: [:logger, :con_cache, :httpotion]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:gettext, "0.16.1"},
      {:plug_cowboy, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:con_cache, "~> 0.12.1"},
      {:httpotion, "~> 3.1.0"},
      {:uuid, "~> 1.1"},
      {:excoveralls, "0.10.3", only: :test}
    ]
  end
end
