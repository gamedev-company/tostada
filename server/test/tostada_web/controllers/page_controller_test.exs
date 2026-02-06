defmodule TostadaWeb.PageControllerTest do
  use TostadaWeb.ConnCase

  test "GET / renders landing page for unauthenticated users", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Phoenix + SvelteKit Boilerplate"
  end

  test "GET / redirects authenticated users to /app", %{conn: conn} do
    conn = conn |> log_in_user(Tostada.AccountsFixtures.user_fixture()) |> get(~p"/")
    assert redirected_to(conn) == ~p"/app"
  end
end
