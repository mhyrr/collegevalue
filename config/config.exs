# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :collegevalue,
  ecto_repos: [Collegevalue.Repo]

# Configures the endpoint
config :collegevalue, CollegevalueWeb.Endpoint,
  live_view: [
    signing_salt: "OKdPxB8pAsnmcv4Pu40o3Uez1NTQrqyV"
  ],
  url: [host: "localhost"],
  secret_key_base: "U/fjAaxCRdWoMibpAndLqRS7zarHVZZIeac8LTf3nswE/BVhjVaeLRMhw2y/X/Ud",
  render_errors: [view: CollegevalueWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Collegevalue.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
