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

  client = ElixirRss.WeChat.Sandbox

  pipeline :login_layout do
    plug :put_root_layout, {ElixirRssWeb.LayoutView, :login}
  end

  pipeline :auth do
    plug ElixirRssWeb.CheckSession
  end

  pipeline :wechat_oauth2 do
    plug WeChat.Plug.CheckOauth2, client: client, env: "dev"
  end

  scope "/", ElixirRssWeb do
    pipe_through :browser

    live "/", PageLive, :index
    get "/preview/:last_updated", PreviewController, :old
    get "/:name", PreviewController, :show

    scope "/login" do
      pipe_through :login_layout
      live "/", LoginLive, :index
    end

    scope "/login/oauth2/:token" do
      pipe_through :wechat_oauth2
      get "/", LoginOAuth2Controller, :index
    end

    get "/admin/login/:token", AdminController, :handle_token

    scope "/admin" do
      pipe_through :auth
      live "/", AdminLive, :index
    end
  end

  scope "/api", ElixirRssWeb do
    pipe_through :api
    post "/:name", PreviewController, :show_json
  end

  scope "/wx/oauth2", WeChat.Plug do
    if match?(:prod, Mix.env()) do
      get "/:env/callback/*path", WebPageOAuth2, client: client, action: :hub_oauth2_callback
    end

    get "/callback/*path", WebPageOAuth2, client: client, action: :oauth2_callback

    if Mix.env() in [:dev, :test] do
      get "/*path", WebPageOAuth2, client: client, action: :hub_client_oauth2
    else
      get "/*path", WebPageOAuth2, client: client, action: :oauth2
    end
  end
end
