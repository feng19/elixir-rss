defmodule ElixirRss.Parser.Daily do
  @moduledoc false
  import ElixirRss.Utils

  def parse(%{data: list}, params) do
    after_at = get_after_at(params) |> max(System.system_time(:second) - 7 * 86400) |> to_string()
    {updated_at_info, params} = Map.pop(params, "updated_at", %{})

    {_n, sections, links, updated_at_info} =
      Enum.reduce(list, {1, [], [], updated_at_info}, &format_info(&1, &2, params, after_at))

    references =
      links
      |> Enum.reverse()
      |> List.flatten()
      |> references_section()

    content =
      Enum.reverse(sections)
      |> Kernel.++([references])
      |> Floki.raw_html()

    date = :erlang.date() |> Date.from_erl!() |> Date.to_iso8601()
    {:ok, %{content: content, updated_at: updated_at_info, title: "Elixir Daily #{date}"}}
  end

  def format_info(
        %{data: data} = info,
        {n, sections_acc, links_acc, updated_at_acc} = acc,
        params,
        after_at
      ) do
    after_at = Map.get(updated_at_acc, info.key, after_at)
    params = Map.put(params, "after", after_at)

    info
    |> Map.put(:data, data)
    |> info.parser.parse(params, n)
    |> case do
      {:ok, %{items: items, links: links, n: n_new, updated_at: updated_at}}
      when items != [] ->
        {n_new, [chapter_section(info.name, items) | sections_acc], [links | links_acc],
         Map.put(updated_at_acc, info.key, updated_at)}

      _ ->
        acc
    end
  end

  def format_info(_, acc), do: acc
end
