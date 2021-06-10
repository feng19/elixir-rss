defmodule ElixirRss.Parser.ElixirWeekly do
  @moduledoc false
  import ElixirRss.Utils

  @p_style {"style", "margin: 10px 0;"}

  def parse(%{data: html}, _params) do
    [title | content] =
      Floki.find(html, ".issue-preview .issue-preview__inner")
      |> hd()
      |> Floki.children(include_text: false)
      |> hd()
      |> Floki.children(include_text: false)

    content =
      content
      |> Enum.take_while(fn html ->
        html
        |> Floki.children(include_text: false)
        |> case do
          [{"a", _, ["Submit your blog post/project update"]} | _] -> false
          _ -> true
        end
      end)
      |> format_content()
      |> Floki.raw_html()

    title =
      Floki.text(title)
      |> String.replace("Weekly", " Weekly")
      |> String.replace(" by @elixirstatus", "")

    {:ok, %{content: content, title: title}}
  end

  def format_content(html) do
    {tree, {_n, links}} =
      Floki.traverse_and_update(html, {1, []}, fn
        {"div", _attrs, _children} = div, acc ->
          case Floki.children(div, include_text: false) do
            [] ->
              {div, acc}

            [_] ->
              {div, acc}

            [title_div | children] ->
              chapter_title = Floki.text(title_div)
              {chapter_section(chapter_title, children), acc}
          end

        {"p", attrs, children} = p, acc ->
          case Floki.children(p, include_text: false) do
            [title, _br, description] ->
              {article_section(title, [description]), acc}

            [title, description] ->
              {one_line_article_section(title, description), acc}

            _ ->
              {{"p", [@p_style | attrs], children}, acc}
          end

        {"a", _attrs, _children} = html_node, {n, list} ->
          [href] = Floki.attribute(html_node, "href")
          title = Floki.text(html_node)
          {format_a(title, href, n), {n + 1, [href | list]}}

        other, acc ->
          {other, acc}
      end)

    tree ++ [references_section(links)]
  end
end
