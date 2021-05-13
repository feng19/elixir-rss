defmodule ElixirRssWeb.PageLive do
  use ElixirRssWeb, :live_view
  alias ElixirRss

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
         {:ok, %{content: content, updated_at: updated_at_info}} <-
           ElixirRss.show("daily", %{"after" => last_updated}) do
      updated_at = Enum.min_by(updated_at_info, &elem(&1, 1))
      {:noreply, assign(socket, last_updated: updated_at, preview: content)}
    else
      error ->
        {:noreply,
         socket
         |> put_flash(:error, inspect(error))
         |> assign(last_updated: last_updated)}
    end
  end

  defp preview(last_updated) do
    with {:ok, %{content: content, updated_at: updated_at_info}} <- ElixirRss.show("daily") do
      updated_at = Enum.min_by(updated_at_info, &elem(&1, 1))
      {updated_at, content}
    else
      _ -> {last_updated, ""}
    end
  end
end
