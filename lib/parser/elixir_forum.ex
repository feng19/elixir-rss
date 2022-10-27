defmodule ElixirRss.Parser.ElixirForum do
  @moduledoc false
  import ElixirRss.Utils

  def parse(%{data: feed} = info, params, n \\ 1) do
    after_at = get_after_at(params)
    ignore_desc? = Map.has_key?(info, :ignore_desc)

    {n, items, links} =
      Enum.reduce(
        feed.items,
        {n, [], []},
        fn %{published_at: published_at} = item, {n, items_acc, links_acc} ->
          if parse_strftime(published_at) > after_at do
            {n + 1, [format_item(item, n, ignore_desc?) | items_acc], [item.link | links_acc]}
          else
            {n, items_acc, links_acc}
          end
        end
      )

    updated_at = parse_strftime(feed.updated_at)
    {:ok, %{updated_at: updated_at, items: Enum.reverse(items), links: Enum.reverse(links), n: n}}
  end

  defp format_item(%{title: title, link: link}, n, true) do
    one_line_article_section([format_a(title, link, n)])
  end

  defp format_item(%{title: title, description: description, link: link}, n, _ignore_desc?) do
    description =
      Floki.parse_document!(description)
      |> Floki.text()
      |> String.splitter(" ", trim: true)
      |> Enum.take(160)
      |> Enum.join(" ")
      |> String.split("\n")
      |> Enum.reject(&match?("", &1))
      |> Enum.intersperse({"br", [], []})

    article_section(format_a(title, link, n), description ++ [" ..."])
  end

  defp parse_strftime(published_at) do
    published_at
    |> Timex.parse!("%a, %d %b %Y %T %z", :strftime)
    |> DateTime.to_unix()
  end
end
