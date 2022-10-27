import Config

config :elixir_rss,
  tencent_translator_access_info: %{
    access_key_id: System.get_env("T_TRANSLATOR_AK_ID", ""),
    access_key_secret: System.get_env("T_TRANSLATOR_AK_SECRET", "")
  }

config :floki, :html_parser, Floki.HTMLParser.Html5ever
