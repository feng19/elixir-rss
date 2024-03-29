defmodule ElixirRss.Parser.Daily do
  @moduledoc false
  import ElixirRss.Utils

  def parse(%{data: list}, params) do
    default_after_at =
      get_after_at(params) |> max(System.system_time(:second) - 7 * 86400) |> to_string()

    updated_at_info = get_update_at(params)

    {_n, sections, links, updated_at_info} =
      Enum.reduce(
        list,
        {1, [], [], updated_at_info},
        &format_info(&1, &2, params, default_after_at)
      )

    references =
      links
      |> Enum.reverse()
      |> List.flatten()
      |> references_section()

    content =
      Enum.reverse(sections)
      |> Kernel.++([references])
      |> Floki.raw_html()

    date = :erlang.date() |> Date.from_erl!() |> Date.to_iso8601() |> String.slice(5..-1)
    {:ok, %{content: content, updated_at: updated_at_info, title: "Elixir 社区日报 #{date}"}}
  end

  defp get_update_at(params) do
    [
      "elixir-status",
      "dashbit",
      "elixir-news",
      "phoenix-news",
      "nerves-news",
      "erlang-news",
      "events",
      "libraries",
      "elixir-forum",
      "elixir-lang",
      "nx-news"
    ]
    |> Enum.reduce(%{}, fn key, acc ->
      if v = Map.get(params, key) do
        Map.put(acc, key, v)
      else
        acc
      end
    end)
  end

  def format_info(
        %{key: key, data: data} = info,
        {n, sections_acc, links_acc, updated_at_acc} = acc,
        params,
        default_after_at
      ) do
    after_at = Map.get(updated_at_acc, key, default_after_at)
    params = Map.put(params, "after", after_at)

    info
    |> Map.put(:data, data)
    |> info.parser.parse(params, n)
    |> case do
      {:ok, %{items: items, links: links, n: n_new, updated_at: updated_at}}
      when items != [] ->
        {n_new, [chapter_section(info.name, items) | sections_acc], [links | links_acc],
         Map.put(updated_at_acc, key, updated_at)}

      _ ->
        acc
    end
  end

  def format_info(_, acc, _, _), do: acc
end
