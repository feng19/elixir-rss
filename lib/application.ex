defmodule ElixirRss.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Supervisor.start_link([ElixirRss.Server], strategy: :one_for_one, name: ElixirRss.Supervisor)
  end
end
