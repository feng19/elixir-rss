defmodule ElixirRss.Utils do
  @moduledoc false

  def iso8601_to_unix(iso8601) do
    {:ok, dt, 0} = DateTime.from_iso8601(iso8601)
    DateTime.to_unix(dt)
  end

  def traverse_links(html, {n, links} \\ {0, []}) do
    Floki.traverse_and_update(html, {n, links}, fn
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

      other, acc ->
        {other, acc}
    end)
  end

  def format_a(link, link, n), do: format_a("link", link, n)

  def format_a(title, link, n) do
    {"a",
     [
       {"style", "font-size: 1.125rem; text-decoration: underline;"},
       {"href", link},
       {"target", "_blank"}
     ], [title, {"sup", [], ["[#{n}]"]}]}
  end

  def format_chapter(title) do
    {"section",
     [
       {"style",
        "border-bottom: 1px solid rgb(239, 112, 96);display: inline-block;padding: 0 2rem;box-sizing: border-box;"}
     ],
     [
       {"span",
        [
          {"style",
           "max-width: 100%;color: rgb(234, 84, 20);font-size: 1.25rem;font-weight: bold;"},
          {"class", "chapter_title"}
        ], [title]}
     ]}
  end

  def chapter_section(chapter_title, children) do
    {"section",
     [
       {"style", "padding: 1.5rem 1.5rem 0rem 1.5rem;line-height: 1.75em;"},
       {"class", "chapter"}
     ],
     [
       {"section", [{"style", "text-align: center;"}], [format_chapter(chapter_title)]},
       {"section", [{"class", "articles"}], children}
     ]}
  end

  def article_section(title, description) do
    {"section", [{"style", "margin: 10px 0;"}, {"class", "article"}],
     [
       title,
       {"br", [], []},
       {"section", [{"style", "color: #666;margin-left: 1rem;"}, {"class", "description"}],
        description}
     ]}
  end

  def references_section(links) do
    {references, _} =
      Enum.map_reduce(links, 1, fn link, n ->
        {{"p", [{"style", "margin: 3px 0;"}], [{"code", [], "[#{n}]  "}, {"em", [], [link]}]},
         n + 1}
      end)

    chapter_section("References", references)
  end

  def get_after_at(params) do
    Map.get(params, "after", "0")
    |> Integer.parse()
    |> case do
      :error -> 0
      {int, _} -> int
    end
  end
end
