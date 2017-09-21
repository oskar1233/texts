use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sample_guardian, SampleGuardianWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :sample_guardian, SampleGuardian.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "oskar1233",
  password: "78335500",
  database: "sample_guardian_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
