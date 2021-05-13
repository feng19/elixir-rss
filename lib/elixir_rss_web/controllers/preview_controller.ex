defmodule ElixirRssWeb.PreviewController do
  use ElixirRssWeb, :controller
  require Logger

  def old(conn, params) do
    after_at = Map.pop(params, "last_updated")
    show(conn, Map.put(params, "after", after_at))
  end

  def show(conn, params) do
    {name, params} = Map.pop!(params, "name")
    params = handle_update_at(params)

    content =
      case ElixirRss.show(name, params) do
        {:ok, %{content: content, updated_at: updated_at}} ->
          next_url = current_url(conn, Map.put(updated_at, "name", name))

          """
          <body style="width: 50%; margin: auto auto;">
          <!-- now: #{current_url(conn)} -->
          #{content}
          <!-- next: #{next_url} -->
          </body>
          """

        error ->
          inspect(error)
      end

    html(conn, content)
  end

  defp handle_update_at(params) do
    [
      "elixir-status",
      "dashbit",
      "elixir-news",
      "phoenix-news",
      "nerves-news",
      "erlang-news",
      "events",
      "libraries",
      "elixir-forum"
    ]
    |> Enum.reduce(Map.put(params, "updated_at", %{}), fn key, acc ->
      case Map.pop(acc, key) do
        {nil, _acc} ->
          acc

        {v, acc} ->
          Map.update!(acc, "updated_at", &Map.put(&1, key, v))
      end
    end)
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
