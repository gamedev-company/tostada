defmodule TostadaWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug that requires the current user to be an admin.

  Must be used after authentication plugs that set `conn.assigns.current_scope`.
  """
  import Plug.Conn
  import Phoenix.Controller

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    if user && user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "Admin access required.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
