defmodule ElixirRss.Parser.ElixirLang do
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
            link = item.link
            item = article_section(format_a(item.title, link, n), [])
            {n + 1, [item | items_acc], [link | links_acc]}
          else
            {n, items_acc, links_acc}
          end
        end
      )

    updated_at = iso8601_to_unix(feed.updated_at)
    {:ok, %{updated_at: updated_at, items: Enum.reverse(items), links: Enum.reverse(links), n: n}}
  end
end
