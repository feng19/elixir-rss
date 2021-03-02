import Config

config :elixir_rss, ElixirRssWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}]

config :elixir_rss,
  sandbox_appsecret: System.fetch_env!("WECHAT_SECRET"),
  sandbox_token: System.fetch_env!("WECHAT_TOKEN"),
  token_salt: System.fetch_env!("TOKEN_SALT")
