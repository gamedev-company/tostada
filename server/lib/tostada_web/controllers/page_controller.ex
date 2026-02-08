defmodule TostadaWeb.PageController do
  use TostadaWeb, :controller

  def home(conn, _params) do
    # Redirect authenticated users to the app shell
    if conn.assigns[:current_scope] && conn.assigns.current_scope.user do
      redirect(conn, to: ~p"/app")
    else
      render(conn, :home)
    end
  end
end
