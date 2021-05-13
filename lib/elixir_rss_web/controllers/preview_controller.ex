defmodule ElixirRssWeb.PreviewController do
  use ElixirRssWeb, :controller
  require Logger
  alias ElixirRss.Parser

  def old(conn, params) do
    after_at = Map.pop(params, "last_updated")
    show(conn, Map.put(params, "after", after_at))
  end

  def show(conn, params) do
    {name, params} = Map.pop!(params, "name")

    content =
      case ElixirRss.show(name, params) do
        {:ok, %{content: content}} -> content
        error -> inspect(error)
      end

    html(conn, """
    <body style="width: 50%; margin: auto auto;">
    #{content}
    </body>
    """)
  end
end
