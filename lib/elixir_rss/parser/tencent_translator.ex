defmodule ElixirRss.Parser.TencentTranslator do
  @moduledoc false
  require Logger
  @host "tmt.tencentcloudapi.com"
  @region "ap-guangzhou"
  @url "https://" <> @host

  def translation(text) do
    with {:ok, %{"TargetText" => translated}} <-
           call(%{
             "Action" => "TextTranslate",
             "Version" => "2018-03-21",
             "Region" => @region,
             "Source" => "en",
             "Target" => "zh",
             "SourceText" => text,
             "ProjectId" => 0,
             "UntranslatedText" => "elixir"
           }) do
      translated
    end
  end

  def batch_translation(texts) do
    base = %{
      "Action" => "TextTranslateBatch",
      "Version" => "2018-03-21",
      "Region" => @region,
      "Source" => "en",
      "Target" => "zh",
      "ProjectId" => 0
    }

    Map.put(base, "SourceTextList", texts)
    |> call()
    |> case do
      {:ok, %{"TargetTextList" => translated_list}} -> translated_list
      error -> error
    end
  end

  def call(data) do
    {action, data} = Map.pop!(data, "Action")
    {version, data} = Map.pop!(data, "Version")
    {region, data} = Map.pop!(data, "Region")
    body = Jason.encode!(data)
    date = Date.utc_today() |> Date.to_string()
    content_type = "application/json; charset=utf-8"
    timestamp = System.system_time(:second)
    hashed_request_payload = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)

    canonical_request =
      "POST\n/\n\ncontent-type:#{content_type}\nhost:#{@host}\n\ncontent-type;host\n" <>
        hashed_request_payload

    hashed_canonical_request =
      :crypto.hash(:sha256, canonical_request) |> Base.encode16(case: :lower)

    credential_scope = "#{date}/tmt/tc3_request"

    string_to_sign =
      "TC3-HMAC-SHA256\n#{timestamp}\n#{credential_scope}\n#{hashed_canonical_request}"

    %{access_key_id: secret_id, access_key_secret: secret_key} =
      Application.get_env(:elixir_rss, :tencent_translator_access_info)

    secret_date = :crypto.mac(:hmac, :sha256, "TC3" <> secret_key, date)
    secret_service = :crypto.mac(:hmac, :sha256, secret_date, "tmt")
    secret_signing = :crypto.mac(:hmac, :sha256, secret_service, "tc3_request")

    signature =
      :crypto.mac(:hmac, :sha256, secret_signing, string_to_sign) |> Base.encode16(case: :lower)

    authorization =
      "TC3-HMAC-SHA256 Credential=#{secret_id}/#{credential_scope}, SignedHeaders=content-type;host, Signature=#{signature}"

    headers = [
      {"X-TC-Action", action},
      {"X-TC-Region", region},
      {"X-TC-Timestamp", timestamp},
      {"X-TC-Version", version},
      {"Authorization", authorization},
      {"Content-Type", content_type},
      {"Host", @host}
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
      {:ok, %{status: 200, body: %{"Response" => response}}} ->
        {:ok, response}

      error ->
        error
    end
  end
end
