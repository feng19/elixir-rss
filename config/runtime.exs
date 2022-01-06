import Config

config :elixir_rss, ElixirRssWeb.Endpoint,
  server: true,
  http: [port: System.get_env("PORT", "4000")]

config :elixir_rss,
  aliyun_translator_access_info: %{
    access_key_id: System.get_env("TRANSLATOR_AK_ID", ""),
    access_key_secret: System.get_env("TRANSLATOR_AK_SECRET", "")
  },
  tencent_translator_access_info: %{
    access_key_id: System.get_env("T_TRANSLATOR_AK_ID", ""),
    access_key_secret: System.get_env("T_TRANSLATOR_AK_SECRET", "")
  }
