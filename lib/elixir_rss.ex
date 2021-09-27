defmodule ElixirRss do
  alias ElixirRss.Parser

  def list do
    [
      %{
        type: :list,
        name: "Daily",
        path: "daily",
        list: [
          %{
            type: :rss,
            name: "ElixirStatus",
            key: "elixir-status",
            url: "https://elixirstatus.com/rss",
            parser: Parser.ElixirStatus
          },
          %{
            type: :rss,
            name: "Dashbit",
            key: "dashbit",
            url: "https://dashbit.co/feed",
            parser: Parser.Dashbit
          },
          %{
            type: :rss,
            name: "Elixir News",
            key: "elixir-news",
            url: "https://elixirforum.com/c/elixir-news/28.rss",
            parser: Parser.ElixirForum,
            ignore_desc: true
          },
          %{
            type: :rss,
            name: "Phoenix News",
            key: "phoenix-news",
            url: "https://elixirforum.com/c/phoenix-forum/phoenix-news/52.rss",
            parser: Parser.ElixirForum,
            ignore_desc: true
          },
          %{
            type: :rss,
            name: "Nerves News",
            key: "nerves-news",
            url: "https://elixirforum.com/c/nerves-forum/nerves-news/77.rss",
            parser: Parser.ElixirForum,
            ignore_desc: true
          },
          %{
            type: :rss,
            name: "Erlang News",
            key: "erlang-news",
            url: "https://elixirforum.com/c/erlang-forum/erlang-news/85.rss",
            parser: Parser.ElixirForum,
            ignore_desc: true
          },
          %{
            type: :rss,
            name: "Libraries",
            key: "libraries",
            url: "https://elixirforum.com/c/libraries/43.rss",
            parser: Parser.ElixirForum,
            ignore_desc: true
          },
          %{
            type: :rss,
            name: "Events & Confs & Meetups",
            key: "events",
            url: "https://elixirforum.com/c/events-confs-meet-ups/11.rss",
            parser: Parser.ElixirForum
          },
          %{
            type: :rss,
            name: "ElixirForum Announcements",
            key: "elixir-forum",
            url: "https://elixirforum.com/c/announcements/22.rss",
            parser: Parser.ElixirForum
          },
          %{
            type: :rss,
            name: "ElixirLang",
            key: "elixir-lang",
            url: "https://elixir-lang.org/atom.xml",
            parser: Parser.ElixirLang
          }
        ],
        parser: Parser.Daily
      },
      %{
        type: :html,
        name: "ElixirWeekly",
        path: "weekly",
        url: "https://elixirweekly.net",
        parser: Parser.ElixirWeekly
      },
      %{
        type: :html,
        name: "ElixirWeekly",
        path: "elixir-weekly",
        url: "https://elixirweekly.net",
        parser: Parser.ElixirWeekly
      },
      %{
        type: :html,
        name: "ElixirRadar",
        path: "elixir-radar",
        url: :get_from_params,
        parser: Parser.ElixirRadar
      }
    ]
  end

  def show(path, params \\ %{}) do
    with info when is_map(info) <- Enum.find(list(), &match?(%{path: ^path}, &1)),
         {:ok, data} <- Parser.parse(info, params) do
      is_translate = Map.has_key?(params, "translate") or Map.has_key?(params, "t")

      info
      |> Map.put(:data, data)
      |> info.parser.parse(params)
      |> case do
        {:ok, %{content: content} = info} when is_translate ->
          {:ok, %{info | content: translate(content)}}

        other ->
          other
      end
    end
  end

  def translate(content) do
    content_html = Floki.parse_document!(content)

    collect_translate_source(content_html)
    |> Parser.TencentTranslator.batch_translation()
    |> case do
      translated_texts when is_list(translated_texts) ->
        insert_translated_texts(content_html, translated_texts)

      _ ->
        content
    end
  end

  defp collect_translate_source(content_html) do
    Floki.find(content_html, "section.article")
    |> Floki.traverse_and_update(fn
      {"a", attrs, children} -> {"a", attrs, Enum.reject(children, &is_tuple/1)}
      other -> other
    end)
    |> Stream.flat_map(fn
      {_, _, [a, _br, description]} ->
        [Floki.text(a), Floki.text(description)]

      {_, _, [a, _description]} ->
        [Floki.text(a)]

      {_, _, [a]} ->
        [Floki.text(a)]
    end)
    |> Enum.map(&String.trim/1)
  end

  defp insert_translated_texts(content_html, translated_texts) do
    content_html
    |> Floki.traverse_and_update(translated_texts, fn
      {"section", attrs, children}, acc ->
        if Enum.member?(attrs, {"class", "article"}) do
          case children do
            [a, br, {d_tag, d_attrs, d_children}] ->
              [a_t, desc_t | acc] = acc

              desc_list =
                String.split(desc_t, "\n")
                |> Enum.map(&{"em", [], [&1]})
                |> Enum.intersperse(br)

              section =
                {"section", attrs,
                 [
                   a,
                   br,
                   {"em", [], [a_t]},
                   br,
                   {d_tag, d_attrs, d_children ++ [br | desc_list]}
                 ]}

              {section, acc}

            [a, description] ->
              [a_t | acc] = acc
              {_, d_attrs, _} = description
              d_t = Floki.text(description) |> simple_description2cn()

              section =
                {"section", attrs,
                 [
                   a,
                   description,
                   {"br", [], []},
                   {"em", [], [a_t]},
                   {"span", d_attrs, [d_t]}
                 ]}

              {section, acc}

            [a] ->
              [a_t | acc] = acc

              section =
                {"section", attrs,
                 [
                   a,
                   {"br", [], []},
                   {"em", [], [a_t]}
                 ]}

              {section, acc}
          end
        else
          {{"section", attrs, children}, acc}
        end

      other, acc ->
        {other, acc}
    end)
    |> elem(0)
    |> Floki.raw_html()
  end

  defp simple_description2cn("Podcast"), do: "播客"
  defp simple_description2cn("Video"), do: "视频"
  defp simple_description2cn("Blog post"), do: "博文"
  defp simple_description2cn("Project update"), do: "项目更新"
  defp simple_description2cn("Conference"), do: "研讨会"
  defp simple_description2cn("Misc"), do: "其他"
  defp simple_description2cn("Meetup"), do: "聚会"
  defp simple_description2cn(description), do: description
end
