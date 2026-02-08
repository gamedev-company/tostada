defmodule TostadaWeb.Plugs.Cors do
  @moduledoc """
  Simple CORS plug for development.
  In production, configure proper CORS at the reverse proxy level.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()

    # In development, allow localhost origins
    if allowed_origin?(origin) do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "content-type, authorization")
      |> put_resp_header("access-control-allow-credentials", "true")
      |> handle_preflight()
    else
      conn
    end
  end

  defp allowed_origin?(nil), do: false

  defp allowed_origin?(origin) do
    # Allow localhost origins in development
    String.starts_with?(origin, "http://localhost:") or
      String.starts_with?(origin, "http://127.0.0.1:")
  end

  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(204, "")
    |> halt()
  end

  defp handle_preflight(conn), do: conn
end
