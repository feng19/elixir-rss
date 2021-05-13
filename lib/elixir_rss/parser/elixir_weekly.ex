defmodule ElixirRss.Parser.ElixirWeekly do
  @moduledoc false
  alias ElixirRss.Utils

  @p_style {"style", "margin: 10px 0;"}

  def parse(%{data: html}, _params) do
    content =
      Floki.find(html, ".issue-preview .issue-preview__inner")
      |> hd()
      |> Floki.children(include_text: false)
      |> hd()
      |> Floki.children(include_text: false)
      |> Enum.drop(1)
      |> Enum.take_while(fn html ->
        html
        |> Floki.children(include_text: false)
        |> case do
          [{"a", _, ["Submit your blog post/project update"]} | _] -> false
          _ -> true
        end
      end)
      |> format()
      |> Floki.raw_html()

    {:ok, %{content: content}}
  end

  def format(html) do
    {tree, {_n, links}} =
      Floki.traverse_and_update(html, {1, []}, fn
        {"div", attrs, children}, acc ->
          {{"section", attrs, children}, acc}

        {"p", attrs, children}, acc ->
          {{"p", [@p_style | attrs], children}, acc}

        {"a", attrs, children} = html_node, {n, list} ->
          [href] = Floki.attribute(html_node, "href")
          {{"a", attrs, children ++ [{"sup", [], "[#{n}]"}]}, {n + 1, [href | list]}}

        other, acc ->
          {other, acc}
      end)

    tree ++ [Utils.references_section(links)]
  end
end
