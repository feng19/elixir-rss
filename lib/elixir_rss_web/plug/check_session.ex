defmodule ElixirRssWeb.CheckSession do
  use ElixirRssWeb, :controller
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "openid") do
      nil ->
        conn
        |> redirect(to: ElixirRssWeb.Router.Helpers.login_path(conn, :index))
        |> halt()

      _openid ->
        conn
    end
  end
end
