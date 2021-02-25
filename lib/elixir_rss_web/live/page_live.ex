defmodule ElixirRssWeb.PageLive do
  use ElixirRssWeb, :live_view
  alias ElixirRss.Parser

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, last_updated: 0, preview: "")}
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
end
