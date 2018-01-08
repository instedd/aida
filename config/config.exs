# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :aida,
  ecto_repos: [Aida.Repo]

# Configures the endpoint
config :aida, AidaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Mt5cc4Oyj6PoeHp0bptg4YDmAfE8V53UqqBgd5t003SMRCD3XcO0IKkXZ+yXu9sA",
  render_errors: [view: AidaWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Aida.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

version = case File.read("VERSION") do
  {:ok, version} -> String.trim(version)
  {:error, :enoent} -> "#{Mix.Project.config[:version]}-#{Mix.env}"
end

config :aida, version: version

sentry_enabled = String.length(System.get_env("SENTRY_DSN") || "") > 0
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  public_dsn: System.get_env("SENTRY_PUBLIC_DSN"),
  environment_name: Mix.env || :dev,
  included_environments: (if sentry_enabled, do: [:prod, :dev], else: []),
  release: version

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
