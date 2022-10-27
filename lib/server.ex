defmodule ElixirRss.Server do
  import Plug.Cowboy.Conn
  require Logger

  def child_spec(_ \\ nil) do
    port = System.get_env("PORT", "4000") |> String.to_integer()

    paths = [
      {"/", __MODULE__, []},
      {"/:name", __MODULE__, []}
    ]

    Plug.Cowboy.child_spec(scheme: :http, plug: ElixirRss, port: port, dispatch: [{:_, paths}])
  end

  def init(req, _opts) do
    name = :cowboy_req.binding(:name, req, "weekly")
    params = :cowboy_req.parse_qs(req) |> Map.new()
    Logger.debug("name: #{name}, params: #{inspect(params)}")

    body =
      case ElixirRss.show(name, params) do
        {:ok, %{content: content, title: title} = data} ->
          updated_at = Map.get(data, :updated_at, "")

          """
          <body style="width: 50%; margin: auto auto;">
          <!-- now: #{inspect(params)} -->
          <h1>#{title}</h1>
          #{content}
          <!-- updated_at: #{updated_at} -->
          </body>
          """

        error ->
          inspect(error)
      end

    html = """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>ElixirRss</title>
      </head>
      <body>#{body}</body>
    </html>
    """

    send_resp(req, 200, [{"content-type", "text/html; charset=utf-8"}], html)
  end
end
