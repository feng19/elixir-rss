defmodule ElixirRss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ElixirRssWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ElixirRss.PubSub},
      # Start the Endpoint (http/https)
      ElixirRssWeb.Endpoint
      # Start a worker by calling: ElixirRss.Worker.start_link(arg)
      # {ElixirRss.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirRss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElixirRssWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
