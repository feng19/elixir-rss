defmodule ElixirRssWeb.PreviewController do
  use ElixirRssWeb, :controller
  require Logger

  def old(conn, params) do
    after_at = Map.pop(params, "last_updated")
    show(conn, Map.put(params, "after", after_at))
  end

  def show(conn, params) do
    {name, params} = Map.pop!(params, "name")

    content =
      case ElixirRss.show(name, params) do
        {:ok, %{content: content, title: title} = data} ->
          next_url =
            if updated_at = Map.get(data, :updated_at) do
              current_url(conn, updated_at)
            else
              ""
            end

          """
          <body style="width: 50%; margin: auto auto;">
          <!-- now: #{current_url(conn)} -->
          <h1>#{title} |> RSS</h1>
          #{content}
          <!-- next: #{next_url} -->
          </body>
          """

        error ->
          inspect(error)
      end

    html(conn, content)
  end

  def show_json(conn, params) do
    {name, params} = Map.pop!(params, "name")

    data =
      case ElixirRss.show(name, params) do
        {:ok, data} -> Map.put(data, :params, params)
        error -> %{error: inspect(error)}
      end

    json(conn, data)
  end
end
