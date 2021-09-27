defmodule ElixirRss.Parser.TencentTranslator do
  @moduledoc false
  require Logger
  @host "tmt.tencentcloudapi.com"
  @region "ap-guangzhou"

  def translation(text) do
    with {:ok, %{"TargetText" => translated}} <-
           call("TextTranslate", %{
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
    with {:ok, %{"TargetTextList" => translated_list}} <-
           call("TextTranslateBatch", %{
             "Source" => "en",
             "Target" => "zh",
             "ProjectId" => 0,
             "SourceTextList" => texts
           }) do
      translated_list
    end
  end

  defp call(action, data) do
    ak = Application.get_env(:elixir_rss, :tencent_translator_access_info)

    %{
      host: @host,
      action: action,
      version: "2018-03-21",
      region: @region
    }
    |> Map.merge(ak)
    |> TencentCloud.call(data)
    |> case do
      {:ok, %{status: 200, body: %{"Response" => response}}} -> {:ok, response}
      error -> error
    end
  end
end
