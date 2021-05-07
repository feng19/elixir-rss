defmodule ElixirRss.Parser.ElixirStatus do
  @moduledoc """
  解析 https://elixirstatus.com/rss
  """

  @wrapper_attrs [
    {"style", "line-height: 1.75em;margin-left: 8px;margin-right: 8px;font-size: medium;"}
  ]
  @img_attrs [
    {"style",
     "margin-left: 8px;margin-right: 8px;margin-top: 10px;margin-bottom: 10px;text-align: center;visibility: visible;"}
  ]
  @title_attrs [
    {"class", "center_section"},
    {"class", "title"},
    {"style",
     "color: rgb(234, 84, 20); max-width: 100%; font-size: 15px; box-sizing: border-box !important; overflow-wrap: break-word !important; visibility: visible;"}
  ]
  @desc_attrs [
    {"class", "center_section"},
    {"class", "description"},
    {"style",
     "font-size: 10px;letter-spacing: 1.5px;padding-top: 5px;padding-bottom: 5px;color: rgb(180,180,180);box-sizing: border-box;"}
  ]
  @content_attrs [{"style", "margin-left: 8px;margin-right: 8px;font-size: 12px;"}]
  # @link_attrs [{"style", "margin-left: 8px;margin-right: 8px;"}]

  defp client do
    Tesla.client(
      [
        Tesla.Middleware.Retry,
        {Tesla.Middleware.Timeout, timeout: 30_000},
        Tesla.Middleware.Logger
      ],
      Tesla.Adapter.Hackney
    )
  end

  def preview(feed, last_updated \\ 0, wechat_client \\ nil, path \\ "preview/preview.html") do
    {:ok, last_updated, content} = transform_feed(feed, last_updated, wechat_client)
    [prefix, suffix] = String.split(path, ".", parts: 2)
    path = "#{prefix}_#{last_updated}.#{suffix}"
    File.write!(path, content)
    System.cmd("open", [path])
    {:ok, content}
  end

  def parse(url \\ "https://elixirstatus.com/rss") do
    with {:ok, %{status: 200, body: xml}} <- Tesla.get(client(), url) do
      Fiet.parse(xml)
    end
  end

  # todo parser => json
  def transform_feed(feed, last_updated \\ 0, wechat_client \\ nil) do
    items =
      feed.items
      |> Enum.map(&%{&1 | published_at: transform_published_at(&1.published_at)})
      |> Enum.filter(&(&1.published_at > last_updated))

    if Enum.empty?(items) do
      {:ok, last_updated, ""}
    else
      html =
        items
        |> Stream.map(&transform_description(&1.description, wechat_client))
        |> Enum.intersperse({"p", [], [{"br", [], []}]})
        |> Floki.raw_html()

      last_updated = items |> Enum.max_by(& &1.published_at) |> Map.get(:published_at)
      {:ok, last_updated, html}
    end
  end

  defp transform_published_at(published_at) do
    published_at
    |> Timex.parse!("%_d %b %Y %T %z", :strftime)
    |> DateTime.to_unix()
  end

  defp transform_description(description, wechat_client) do
    table = get_table_from_description(description)
    [title, desc | contents] = table
    title = format_title(title)
    desc = format_desc(desc)

    head =
      {"section", [{"style", "margin-top: 10px;margin-bottom: 10px;text-align: center;"}],
       [title, desc]}

    # hr 分割线
    {contents, [_hr, _link | _]} = Enum.split_while(contents, &(not match?({"hr", _, _}, &1)))

    images =
      find_images(contents)
      |> Task.async_stream(&download_and_upload_image(wechat_client, &1), timeout: 600_000)
      |> Enum.reduce([], fn
        {:ok, nil}, acc -> acc
        {:ok, result}, acc -> [result | acc]
        _, acc -> acc
      end)

    contents = format_contents(contents, images)
    content = {"section", [], contents}

    {"section", @wrapper_attrs, [head, content]}
  end

  defp format_title({_, _, children}) do
    # title
    {"section",
     [
       {"style",
        "display: inline-block;border-bottom: 1px solid rgb(239, 112, 96);padding-right: 45px;padding-left: 45px;box-sizing: border-box;"}
     ],
     [
       {"section", @title_attrs, children}
     ]}
  end

  defp format_desc({_, _, children}) do
    children =
      children
      |> Enum.reject(&is_binary/1)
      |> Floki.traverse_and_update(fn
        {"font", _, children} ->
          children
          |> Enum.reduce([], fn
            text, acc when is_binary(text) ->
              case String.trim(text) do
                "" -> acc
                text -> [text | acc]
              end

            other, acc ->
              [other | acc]
          end)
          |> Enum.reverse()
          |> Enum.intersperse(" ")

        {"i", _, _} ->
          nil

        {"a", _, ["Retweet this announcement"]} ->
          nil

        other ->
          format_a(other)
      end)
      |> Enum.intersperse(" ")
      |> :erlang.iolist_to_binary()
      |> String.trim_trailing("|")
      |> String.trim()

    {"section", @desc_attrs, {"p", [], children}}
  end

  defp format_contents([{"p", _, children} | contents], images) do
    children = Floki.traverse_and_update(children, &(&1 |> format_a() |> format_img(images)))
    [{"p", @content_attrs, children} | format_contents(contents, images)]
  end

  defp format_contents([_ | contents], images), do: format_contents(contents, images)
  defp format_contents([], _images), do: []

  #  defp format_link({link, _, children}) do
  #    children = Floki.traverse_and_update(children, &format_a/1)
  #    {"p", @link_attrs, {link, [], children}}
  #  end
  #
  #  defp format_link(other), do: other

  defp format_a({"a", attrs, children}) do
    case Floki.find(children, "img") do
      [image | _] ->
        image

      _ ->
        a_content =
          if Enum.all?(children, &is_binary/1) do
            IO.iodata_to_binary(children)
          end

        children =
          case List.keyfind(attrs, "href", 0) do
            {_, ^a_content} -> [a_content]
            {_, href} -> ["[" | children] ++ ["](#{href})"]
            _ -> children
          end

        {"a", [{"style", "text-decoration-line: underline;"} | attrs], children}
    end
  end

  defp format_a(other), do: other

  defp format_img({"img", attrs, children}, images) do
    attrs =
      with {{_, url}, attrs} <- List.keytake(attrs, "src", 0),
           {_, new_url} <- List.keyfind(images, url, 0) do
        [{"src", new_url} | attrs]
      else
        _ -> attrs
      end

    {"p", @img_attrs, [{"img", attrs, children}]}
  end

  defp format_img(other, _images), do: other

  defp get_table_from_description(description) do
    description
    |> String.trim()
    |> Floki.parse_document!()
    |> Floki.find("td")
    |> Enum.at(1)
    |> elem(2)
    |> Enum.reject(&is_binary/1)
  end

  defp find_images(table) do
    table
    |> Floki.find("img")
    |> Floki.attribute("src")
    |> Enum.uniq()
  end

  defp download_and_upload_image(nil, _url), do: nil

  defp download_and_upload_image(wechat_client, url) do
    with {:ok, %{status: 200, headers: headers, body: file_data}} <- Tesla.get(client(), url),
         {:ok, ext} <- get_file_ext(url, headers),
         {:ok, %{status: 200, body: json}} <-
           WeChat.Material.upload_image(wechat_client, "image.#{ext}", file_data),
         %{"url" => new_url} <- json do
      {url, new_url}
    else
      _ -> nil
    end
  end

  defp get_file_ext(url, headers) do
    with "" <- url |> Path.basename() |> Path.extname(),
         {_, content_type} <- List.keyfind(headers, "content-type", 0),
         [ext | _] <- MIME.extensions(content_type) do
      {:ok, ext}
    else
      _ -> :unknown_ext
    end
  end
end
