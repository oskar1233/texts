# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :sample_guardian,
  ecto_repos: [SampleGuardian.Repo]

# Configures the endpoint
config :sample_guardian, SampleGuardianWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Yy7atSFkK4xmduZrEtCvB3Lv81TP+qLiqRThCHANHf8ePNsiDNEA1EcuQM+KdFnL",
  render_errors: [view: SampleGuardianWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: SampleGuardian.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
