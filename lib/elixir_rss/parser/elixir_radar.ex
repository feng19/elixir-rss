defmodule ElixirRss.Parser.ElixirRadar do
  @moduledoc false
  import ElixirRss.Utils

  def test() do
    html =
      "/Users/panwenfu/Downloads/Elixir Radar 288.html"
      |> File.read!()
      |> Floki.parse_document!()

    parse(%{data: html}, nil)
  end

  def parse(%{data: html}, _params) do
    content = format(html)
    {:ok, %{content: content}}
  end

  defp format(html) do
    [title | tail] =
      Floki.find(html, "body")
      |> hd()
      |> Floki.children(include_text: false)
      |> unwrap_table()
      # [div, content]
      |> Enum.at(1)
      |> Floki.children(include_text: false)
      # ["read in the browser" div, content, footer_div]
      |> Enum.at(1)
      |> Floki.children(include_text: false)
      |> filter_out_empty_div()
      |> loop_transform_hr()
      |> Enum.chunk_by(&match?({"hr", _, _}, &1))
      |> Enum.reject(&match?([{"hr", _, _}], &1))

    {chapters, {_n, links}} =
      Enum.drop(tail, -1)
      |> Enum.map_reduce({0, []}, fn [chapter_title | children], acc ->
        {children, acc} = Enum.map_reduce(children, acc, &format_item/2)

        chapter =
          chapter_title
          |> Floki.find("h2")
          |> Floki.text()
          |> chapter_section(children)

        {chapter, acc}
      end)

    links = Enum.reverse(links)

    [{"h1", [], [Floki.text(title)]} | chapters]
    |> Kernel.++([references_section(links)])
    |> Floki.raw_html()
  end

  defp unwrap_table(html) do
    Floki.traverse_and_update(html, fn
      {tag, _, children} when tag in ["table", "tbody", "tr"] ->
        filter_out_empty_text(children)

      {"td", _, _} = td ->
        Floki.children(td, include_text: false)
        |> Enum.map(&unwrap_table/1)

      other ->
        filter_out_empty_text(other)
    end)
  end

  defp format_item({"div", _, [{"div", _, children}]}, {n, links}) do
    {title_html, description_tree} =
      case children do
        [
          {"div", _, [{"a", _, _} = title]},
          {"div", _, [{"a", _, _}]},
          {"div", _, description}
        ] ->
          {title, description}

        [
          {"div", _, [{"a", _, _} = title]},
          {"div", _, sub_title},
          {"div", _, description}
        ] ->
          {title, sub_title ++ [{"br", [], []} | description]}

        [
          {"div", _, [{"a", _, _} = title]},
          {"div", _, sub_title}
        ] ->
          {title, sub_title}
      end

    title = Floki.text(title_html)
    link = Floki.attribute(title_html, "href") |> hd() |> transform_radar_url()
    n = n + 1
    {description, {n_news, links}} = traverse_links(description_tree, {n, [link | links]})
    item = article_section(format_a(title, link, n), description)
    {item, {n_news, links}}
  end

  defp transform_radar_url(url) do
    with true <- String.starts_with?(url, "https://sendy.elixir-radar.com/l"),
         {:ok, url} <- ElixirRss.Parser.url_forwarding(url) do
      uri = URI.parse(url)

      query =
        URI.decode_query(uri.query)
        |> Map.drop(["utm_medium", "utm_source"])
        |> URI.encode_query()
        |> case do
          "" -> nil
          query -> query
        end

      URI.to_string(%{uri | query: query})
    else
      _ -> url
    end
  end

  defp loop_transform_hr(children) do
    Enum.map(children, fn
      {"div", _, [{"div", _, [{"p", _, []}]}]} ->
        {"hr", [], []}

      other ->
        other
    end)
  end

  defp filter_out_empty_text({tag, attrs, children}) do
    {tag, attrs, filter_out_empty_text(children)}
  end

  defp filter_out_empty_text(children) do
    Enum.reduce(children, [], fn
      text, acc when is_binary(text) ->
        text = String.trim(text)
        if text != "", do: [text | acc], else: acc

      other, acc ->
        [other | acc]
    end)
    |> Enum.reverse()
    |> List.flatten()
  end

  defp filter_out_empty_div(children) do
    Enum.reject(
      children,
      &is_nil(
        Floki.traverse_and_update(&1, fn
          {"div", _, []} -> nil
          other -> other
        end)
      )
    )
  end
end
