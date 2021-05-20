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
            parser: Parser.ElixirForum
          },
          %{
            type: :rss,
            name: "Phoenix News",
            key: "phoenix-news",
            url: "https://elixirforum.com/c/phoenix-forum/phoenix-news/52.rss",
            parser: Parser.ElixirForum
          },
          %{
            type: :rss,
            name: "Nerves News",
            key: "nerves-news",
            url: "https://elixirforum.com/c/nerves-forum/nerves-news/77.rss",
            parser: Parser.ElixirForum
          },
          %{
            type: :rss,
            name: "Erlang News",
            key: "erlang-news",
            url: "https://elixirforum.com/c/erlang-forum/erlang-news/85.rss",
            parser: Parser.ElixirForum
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
            name: "Libraries & Projects",
            key: "libraries",
            url: "https://elixirforum.com/c/your-libraries-projects/23.rss",
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
      info
      |> Map.put(:data, data)
      |> info.parser.parse(params)
    end
  end
end
