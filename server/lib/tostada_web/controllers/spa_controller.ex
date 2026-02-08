defmodule TostadaWeb.SpaController do
  @moduledoc """
  Controller for serving the SvelteKit SPA.

  All routes under /app/* are handled by serving the SPA's index.html,
  which then handles client-side routing.
  """
  use TostadaWeb, :controller

  @doc """
  Serves the SPA index.html for client-side routing.
  The SPA handles all routing from there.
  """
  def index(conn, _params) do
    spa_path = Application.app_dir(:tostada, "priv/static/app/index.html")

    if File.exists?(spa_path) do
      conn
      |> put_resp_content_type("text/html")
      |> send_file(200, spa_path)
    else
      conn
      |> put_status(:not_found)
      |> put_view(TostadaWeb.ErrorHTML)
      |> render("404.html")
    end
  end
end
