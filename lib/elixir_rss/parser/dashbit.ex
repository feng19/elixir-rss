defmodule ElixirRss.Parser.Dashbit do
  @moduledoc false
  import ElixirRss.Utils

  def parse(%{data: feed}, params, n \\ 1) do
    after_at = get_after_at(params)

    {n, items, links} =
      Enum.reduce(
        feed.items,
        {n, [], []},
        fn %{published_at: published_at} = item, {n, items_acc, links_acc} ->
          if iso8601_to_unix(published_at) > after_at do
            {n + 1, [format_item(item, n) | items_acc], [item.link | links_acc]}
          else
            {n, items_acc, links_acc}
          end
        end
      )

    updated_at = iso8601_to_unix(feed.updated_at)
    {:ok, %{updated_at: updated_at, items: Enum.reverse(items), links: Enum.reverse(links), n: n}}
  end

  defp format_item(%{title: title, description: description, link: link}, n) do
    article_section(format_a(title, link, n), [description])
  end
end
