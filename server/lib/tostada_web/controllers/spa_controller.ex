defmodule TostadaWeb.SpaController do
  @moduledoc """
  Controller for serving the SPA shell.

  All routes under /app/* serve the same `index.html`, which then
  handles client-side routing. If the SPA hasn't been built yet,
  responds with a plain text 404 so the client knows what to do.
  """
  use TostadaWeb, :controller

  def index(conn, _params) do
    spa_path = Application.app_dir(:tostada, "priv/static/app/index.html")

    if File.exists?(spa_path) do
      conn
      |> put_resp_content_type("text/html")
      |> send_file(200, spa_path)
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "SPA not built — run `make build.client`")
    end
  end
end
