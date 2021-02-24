# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :elixir_rss, ElixirRssWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+uyAYBjQKuxUsskDPS5+bP/v7dBGdGGdJktfGbVlNAGzXDx5c27tbiBTu/U26Gv3",
  render_errors: [view: ElixirRssWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ElixirRss.PubSub,
  live_view: [signing_salt: "6Ovszh94"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
