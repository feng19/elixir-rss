defmodule ElixirRss.Parser do
  @moduledoc false

  def download(url) do
    [
      # Tesla.Middleware.Logger,
      Tesla.Middleware.Retry,
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]
    |> Tesla.client(Tesla.Adapter.Hackney)
    |> Tesla.get(url)
  end

  def url_forwarding(url) do
    with {:ok, %{status: 302} = env} <- download(url),
         url when is_binary(url) <- Tesla.get_header(env, "location") do
      {:ok, url}
    else
      _ -> :error
    end
  end

  def parse(info, params \\ nil)

  def parse(%{type: :rss, url: url}, _) do
    with {:ok, %{status: 200, body: xml}} <- download(url) do
      Fiet.parse(xml)
    end
  end

  def parse(%{type: :html, url: :get_from_params}, params) do
    with url when url != nil <- Map.get(params, "url"),
         {:ok, %{status: 200, body: body}} <- download(url) do
      Floki.parse_document(body)
    end
  end

  def parse(%{type: :html, url: url}, _) do
    with {:ok, %{status: 200, body: body}} <- download(url) do
      Floki.parse_document(body)
    end
  end

  def parse(%{type: :list, list: list}, params) do
    {:ok,
     Enum.map(list, fn info ->
       case parse(info, params) do
         {:ok, data} -> Map.put(info, :data, data)
         error -> Map.put(info, :error, error)
       end
     end)}
  end
end
