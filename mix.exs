defmodule Aida.Mixfile do
  use Mix.Project

  def project do
    [
      app: :aida,
      version: "0.5.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      erlc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix, :iex],
        ignore_warnings: ".dialyzer_ignore"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Aida.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 0.13"},
      {:mock, "~> 0.2.0", only: :test},
      {:cowboy, "~> 1.0"},
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false},
      {:ex_json_schema, "~> 0.5.5"},
      {:cors_plug, "~> 1.4"},
      {:timex, "~> 3.0", override: true},
      {:sentry, "~> 6.0"},
      {:ecto_atom, "~> 1.0.0"},
      {:kcl, "~> 1.0"},
      {:msgpax, "~> 2.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
