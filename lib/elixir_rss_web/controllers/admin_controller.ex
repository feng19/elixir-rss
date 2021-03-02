defmodule ElixirRssWeb.AdminController do
  use ElixirRssWeb, :controller
  require Logger

  @max_age 86_400

  def handle_token(conn, %{"token" => token}) do
    case Phoenix.Token.verify(conn, ElixirRssWeb.LoginLive.token_salt(), token, max_age: @max_age) do
      {:ok, %{appid: appid, access_info: access_info}} ->
        path = ElixirRssWeb.Router.Helpers.admin_path(conn, :index)

        conn
        |> put_session("openid", access_info["openid"])
        |> put_session("appid", appid)
        |> put_session("access_info", access_info)
        |> redirect(to: path)

      _ ->
        path = ElixirRssWeb.Router.Helpers.login_path(conn, :index)

        html(conn, """
        <body style="width: 50%; margin: auto auto;">
        token 无效，请重新访问<a href="#{path}">登录页</a>
        </body>
        """)
    end
  end
end
