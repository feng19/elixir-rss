defmodule ElixirRssWeb.PageLive do
  use ElixirRssWeb, :live_view
  alias ElixirRss.Parser

  @impl true
  def mount(params, _session, socket) do
    last_updated =
      params
      |> Map.get("last_updated", "0")
      |> Integer.parse()
      |> case do
        {last_updated, ""} -> last_updated
        _ -> 0
      end

    {last_updated, preview} =
      if last_updated != 0 do
        preview(last_updated)
      else
        {last_updated, ""}
      end

    {:ok, assign(socket, last_updated: last_updated, preview: preview)}
  end

  @impl true
  def handle_event("preview", %{"f" => %{"last_updated" => last_updated}}, socket) do
    with {last_updated, ""} <- Integer.parse(last_updated),
         {:ok, feed} <- Parser.ElixirStatus.parse(),
         {:ok, last_updated, content} <- Parser.ElixirStatus.transform_feed(feed, last_updated) do
      {:noreply, assign(socket, last_updated: last_updated, preview: content)}
    else
      error ->
        {:noreply,
         socket
         |> put_flash(:error, inspect(error))
         |> assign(last_updated: last_updated)}
    end
  end

  defp preview(last_updated) do
    with {:ok, feed} <- Parser.ElixirStatus.parse(),
         {:ok, last_updated, content} <- Parser.ElixirStatus.transform_feed(feed, last_updated) do
      {last_updated, content}
    else
      _ -> {last_updated, ""}
    end
  end
end
