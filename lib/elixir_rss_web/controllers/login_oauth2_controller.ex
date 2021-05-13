defmodule ElixirRssWeb.LoginOAuth2Controller do
  use ElixirRssWeb, :controller
  require Logger

  @max_age 5 * 60
  @openid_whitelist ["oWP97uGZgZRks50Q7pwRRDIOrLdA"]

  def index(conn, %{"token" => token}) do
    content =
      with openid when openid in @openid_whitelist <- get_session(conn, "openid"),
           {:ok, uuid} <-
             Phoenix.Token.verify(conn, ElixirRssWeb.LoginLive.token_salt(), token,
               max_age: @max_age
             ) do
        appid = get_session(conn, "appid")
        access_info = get_session(conn, "access_info")
        payload = %{result: "success", appid: appid, access_info: access_info}
        topic = "login:" <> uuid
        ElixirRssWeb.Endpoint.broadcast(topic, "login_result", payload)
        "登录成功"
      else
        {:error, error} -> inspect(error)
        _error -> "请联系管理员给予登录权限"
      end

    html(conn, """
    <body style="width: 50%; margin: auto auto;">
    #{content}
    </body>
    """)
  end
end
