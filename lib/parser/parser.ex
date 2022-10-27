defmodule ElixirRss.Parser do
  @moduledoc false
  require Logger

  def download(url) do
    opts =
      if proxy =
           System.get_env("HTTP_PROXY") || System.get_env("http_proxy") ||
             System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
        Logger.debug("Using PROXY: #{proxy}")
        %{host: host, port: port} = URI.parse(proxy)
        [proxy: {host, port}]
      else
        []
      end

    [
      # Tesla.Middleware.Logger,
      Tesla.Middleware.Retry,
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]
    |> Tesla.client({Tesla.Adapter.Hackney, opts})
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

  def download_and_parse(info, params \\ nil)

  def download_and_parse(%{type: :rss, url: url}, _) do
    case download(url) do
      {:ok, %{status: 200, body: xml}} ->
        Fiet.parse(xml)

      error ->
        Logger.warn("download error:\n#{inspect(error)}")
        {:error, error}
    end
  end

  def download_and_parse(%{type: :html, url: :get_from_params}, params) do
    with url when url != nil <- Map.get(params, "url"),
         {:ok, %{status: 200, body: body}} <- download(url) do
      Floki.parse_document(body)
    else
      error ->
        Logger.warn("download error:\n#{inspect(error)}")
        {:error, error}
    end
  end

  def download_and_parse(%{type: :html, url: url}, _) do
    case download(url) do
      {:ok, %{status: 200, body: body}} ->
        Floki.parse_document(body)

      error ->
        Logger.warn("download error:\n#{inspect(error)}")
        {:error, error}
    end
  end

  def download_and_parse(%{type: :list, list: list}, params) do
    len = length(list)

    list =
      Task.async_stream(
        list,
        fn info ->
          case download_and_parse(info, params) do
            {:ok, data} -> Map.put(info, :data, data)
            _error -> info
          end
        end,
        timeout: len * 5000
      )
      |> Enum.map(&elem(&1, 1))

    {:ok, list}
  end
end
