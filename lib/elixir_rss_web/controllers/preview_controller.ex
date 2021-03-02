defmodule ElixirRssWeb.PreviewController do
  use ElixirRssWeb, :controller
  require Logger
  alias ElixirRss.Parser

  # page
  def index(conn, params) do
    content =
      with last_updated <- Map.get(params, "last_updated", "0"),
           {last_updated, ""} <- Integer.parse(last_updated),
           {:ok, feed} <- Parser.ElixirStatus.parse(),
           {:ok, _last_updated, content} <- Parser.ElixirStatus.transform_feed(feed, last_updated) do
        """
        <body style="width: 50%; margin: auto auto;">
        #{content}
        </body>
        """
      else
        error -> inspect(error)
      end

    html(conn, content)
  end

  # api
  def preview(conn, params) do
    return =
      with last_updated <- Map.get(params, "last_updated", "0"),
           {last_updated, ""} <- Integer.parse(last_updated),
           {:ok, feed} <- Parser.ElixirStatus.parse(),
           {:ok, last_updated, content} <- Parser.ElixirStatus.transform_feed(feed, last_updated) do
        %{code: 200, last_updated: last_updated, content: content}
      else
        error -> %{code: 4000, msg: inspect(error)}
      end

    json(conn, return)
  end
end
