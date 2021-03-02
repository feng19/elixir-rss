defmodule ElixirRss.WeChat.Sandbox do
  @moduledoc "
  测试号

  [测试号](http://mp.weixin.qq.com/debug/cgi-bin/sandboxinfo?action=showinfo&t=sandbox/index)
  "
  use WeChat,
    code_name: "sandbox",
    appid: "wx552588fc9207532d",
    appsecret: Application.get_env(:elixir_rss, :sandbox_appsecret),
    token: Application.get_env(:elixir_rss, :sandbox_token),
    server_role: Application.get_env(:elixir_rss, :sandbox_server_role)
end
