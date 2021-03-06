use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aida, AidaWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :aida, Aida.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "aida_test",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :aida, Aida.Scheduler,
  batch_size: 5

config :aida, Aida.Crypto,
  private_key: :crypto.strong_rand_bytes(32)
