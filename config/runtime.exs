import Config

config :elixir_rss, ElixirRssWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}]
