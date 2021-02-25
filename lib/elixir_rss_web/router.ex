defmodule ElixirRssWeb.Router do
  use ElixirRssWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ElixirRssWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirRssWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  scope "/api", ElixirRssWeb do
    pipe_through :api
    get "/preview", PreviewController, :preview
  end
end
