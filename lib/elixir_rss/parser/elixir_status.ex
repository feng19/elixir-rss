defmodule ElixirRss.Parser.ElixirStatus do
  @moduledoc false
  import ElixirRss.Utils

  def parse(%{data: feed}, params, n \\ 1) do
    after_at = get_after_at(params)

    {n, updated_at, items, links} =
      Enum.reduce(
        feed.items,
        {n, after_at, [], []},
        fn %{published_at: published_at} = item, {n, last_updated, items_acc, links_acc} ->
          published_at = parse_strftime(published_at)

          if published_at > after_at do
            {item_tree, n, links} = format_item(item, n)

            {n + 1, max(last_updated, published_at), [item_tree | items_acc], links ++ links_acc}
          else
            {n, last_updated, items_acc, links_acc}
          end
        end
      )

    {:ok, %{updated_at: updated_at, items: Enum.reverse(items), links: Enum.reverse(links), n: n}}
  end

  defp format_item(%{title: title, description: description, link: link}, n) do
    {description_tree, {n_new, links}} =
      description
      |> get_table_from_description()
      |> Enum.drop(2)
      |> Enum.split_while(&(not match?({"hr", _, _}, &1)))
      |> elem(0)
      |> Floki.traverse_and_update({n, []}, fn
        {"a", attrs, children}, acc ->
          case Floki.find(children, "img") do
            [image | _] ->
              {image, acc}

            _ ->
              title = Floki.text(children)
              {_, link} = List.keyfind(attrs, "href", 0)
              {n, links} = acc
              n = n + 1
              {format_a(title, link, n), {n, [link | links]}}
          end

        {"p", _, _} = p, acc ->
          {p, acc}

        _other, acc ->
          {nil, acc}
      end)

    item = article_section(format_a(title, link, n), description_tree)
    {item, n_new, Enum.reverse([link | links])}
  end

  def parse_strftime(published_at) do
    published_at
    |> Timex.parse!("%_d %b %Y %T %z", :strftime)
    |> DateTime.to_unix()
  end

  defp get_table_from_description(description) do
    description
    |> String.trim()
    |> Floki.parse_document!()
    |> Floki.find("td")
    |> Enum.at(1)
    |> Floki.children(include_text: false)
  end
end
