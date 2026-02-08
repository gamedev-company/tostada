defmodule TostadaWeb.Api.UserController do
  use TostadaWeb, :controller

  @doc """
  Generate a short-lived token for WebSocket authentication.
  This allows the client to authenticate the WebSocket connection
  when cookies aren't forwarded (e.g., through a dev proxy).
  """
  def socket_token(conn, _params) do
    case conn.assigns[:current_scope] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "not_authenticated"})

      scope ->
        # Token valid for 60 seconds - just enough to establish connection
        token = Phoenix.Token.sign(TostadaWeb.Endpoint, "user socket", scope.user.id)
        json(conn, %{token: token})
    end
  end

  def me(conn, _params) do
    case conn.assigns[:current_scope] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "not_authenticated"})

      scope ->
        user = scope.user

        json(conn, %{
          user: %{
            id: user.id,
            email: user.email,
            display_name: user.display_name,
            is_admin: user.is_admin
          }
        })
    end
  end
end
