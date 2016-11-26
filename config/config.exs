# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :pass_the_chain, PassTheChain.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vTJWsxLpiql4QbXi1hG9G8gVlTvLTzzz3+vfSV4bm0Wu8dF7vYzD3dQ/w72Jx3hu",
  render_errors: [view: PassTheChain.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PassTheChain.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
