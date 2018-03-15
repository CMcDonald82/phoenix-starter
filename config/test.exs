use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phoenix_starter, PhoenixStarterWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :phoenix_starter, PhoenixStarter.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres", #System.get_env("DB_USERNAME"),
  password: "postgres", #System.get_env("DB_PASSWORD"),
  database: "phoenix_starter_test",
  hostname: "postgres", #System.get_env("DB_HOSTNAME"),
  pool: Ecto.Adapters.SQL.Sandbox
