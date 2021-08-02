defmodule ElixirRss.Parser.AliyunTranslator do
  @moduledoc false
  require Logger
  @host "mt.cn-hangzhou.aliyuncs.com"
  @path "/api/translate/web/general"
  @url "http://" <> @host <> @path

  def translation(text, type \\ "text") do
    call(%{
      "Action" => "TranslateGeneral",
      "FormatType" => type,
      "Scene" => "general",
      "SourceLanguage" => "en",
      "TargetLanguage" => "zh",
      "SourceText" => text
    })
  end

  def batch_translation(texts, type \\ "text")

  def batch_translation(texts, type) when is_list(texts) do
    chunk_fun = fn element, {length, acc} ->
      len = String.length(element)
      length = length + len

      if length >= 4000 do
        {:cont, Enum.reverse(acc), {len, [element]}}
      else
        {:cont, {length, [element | acc]}}
      end
    end

    after_fun = fn
      {_, []} -> {:cont, []}
      {_, acc} -> {:cont, Enum.reverse(acc), []}
    end

    texts
    |> Enum.chunk_while({0, []}, chunk_fun, after_fun)
    |> Enum.flat_map(fn list ->
      list
      |> Enum.with_index(fn element, index -> {index, element} end)
      # |> IO.inspect(label: "original")
      |> Map.new()
      |> Jason.encode!()
      |> batch_translation(type)
      |> case do
        {:ok, translated_list} when is_list(translated_list) ->
          translated_list

        error ->
          Logger.warn("translation error: #{inspect(error)}")
          list
      end
    end)
  end

  def batch_translation(text, type) when is_binary(text) do
    case call(%{
           "Action" => "GetBatchTranslate",
           "ApiType" => "translate_standard",
           "FormatType" => type,
           "Scene" => "general",
           "SourceLanguage" => "en",
           "TargetLanguage" => "zh",
           "SourceText" => text
         }) do
      {:ok, translated} when is_binary(translated) ->
        reg = ~r/[“”"][，,]\ ?[“”"]+\ ?(\d+)\ ?[“”"]:\ ?[“”"]/u
        replacement = fn _, x -> "\",\"#{x}\":\"" end

        list =
          translated
          # |> IO.inspect(label: "translated")
          |> String.replace("\\ n", "\\n")
          |> String.replace("\\ N", "\\n")
          |> String.replace("\\ ", "")
          |> String.replace("\\“", "“")
          |> String.replace("\\”", "”")
          |> String.replace_leading("{“0”: “", "{\"0\":\"")
          |> String.replace_trailing("”}", "\"}")
          |> String.replace_trailing("“}", "\"}")
          |> then(&Regex.replace(reg, &1, replacement))
          # |> IO.inspect(label: "before decode")
          |> Jason.decode!()
          |> Enum.sort_by(&(elem(&1, 0) |> String.to_integer()))
          |> Enum.map(&(elem(&1, 1) |> String.trim()))

        {:ok, list}

      error ->
        error
    end
  end

  def call(data) do
    body = Jason.encode!(data)
    body_md5 = body |> :erlang.md5() |> Base.encode64()
    date = Timex.lformat!(Timex.now(), "%a, %d %b %Y %H:%M:%S GMT", "en", :strftime)
    nonce = UUID.uuid1()
    accept = "application/json"
    content_type = "application/json;chrset=utf-8"

    %{access_key_id: access_key_id, access_key_secret: access_key_secret} =
      Application.get_env(:elixir_rss, :aliyun_translator_access_info)

    signature =
      [
        "POST",
        accept,
        body_md5,
        content_type,
        date,
        "x-acs-signature-method:HMAC-SHA1",
        "x-acs-signature-nonce:#{nonce}",
        "x-acs-version:2019-01-02",
        @path
      ]
      |> Enum.join("\n")
      |> then(&:crypto.mac(:hmac, :sha, access_key_secret, &1))
      |> Base.encode64()

    authorization = "acs #{access_key_id}:#{signature}"

    headers = [
      {"Authorization", authorization},
      {"Content-Type", content_type},
      {"Content-MD5", body_md5},
      {"Date", date},
      {"Accept", accept},
      {"Host", @host},
      {"x-acs-signature-nonce", nonce},
      {"x-acs-signature-method", "HMAC-SHA1"},
      {"x-acs-version", "2019-01-02"}
    ]

    [
      # Tesla.Middleware.Logger,
      Tesla.Middleware.Retry,
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      Tesla.Middleware.DecodeJson
    ]
    |> Tesla.client(Tesla.Adapter.Hackney)
    |> Tesla.post(@url, body)
    |> case do
      {:ok, %{status: 200, body: %{"Code" => "200", "Data" => %{"Translated" => translated}}}} ->
        {:ok, translated}

      error ->
        error
    end
  end
end
