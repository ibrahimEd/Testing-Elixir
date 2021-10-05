use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :not_skull, NotSkull.Repo,
  username: "postgres",
  password: "postgres",
  database: "not_skull_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: :infinity

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :not_skull, NotSkullWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :not_skull,
  game_engine: GameEngineMock,
  http_client: HttpClientMock

config :not_skull, email_api_key: System.get_env("SENDGRID_TEST_API_KEY")
