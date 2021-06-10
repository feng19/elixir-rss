import Config

config :elixir_rss, ElixirRssWeb.Endpoint,
  server: true,
  http: [port: System.get_env("PORT", "4000")]

config :elixir_rss,
  sandbox_appsecret: System.get_env("WECHAT_SECRET", ""),
  sandbox_token: System.get_env("WECHAT_TOKEN", ""),
  token_salt: System.get_env("TOKEN_SALT", ""),
  translator_access_info: %{
    access_key_id: System.get_env("TRANSLATOR_AK_ID", ""),
    access_key_secret: System.get_env("TRANSLATOR_AK_SECRET", "")
  }
