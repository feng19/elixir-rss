defmodule ElixirRssWeb.AdminLive do
  use ElixirRssWeb, :live_view

  @impl true
  def mount(_params, %{"openid" => openid}, socket) do
    {:ok, assign(socket, openid: openid)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    Your Openid: <%= @openid %>
    """
  end
end
