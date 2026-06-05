defmodule TostadaWeb.UserAuthTest do
  use TostadaWeb.ConnCase, async: true

  alias Tostada.Accounts
  alias Tostada.Accounts.Scope
  alias TostadaWeb.UserAuth

  import Tostada.AccountsFixtures

  @remember_me_cookie "_tostada_web_user_remember_me"
  @remember_me_cookie_max_age 60 * 60 * 24 * 14

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TostadaWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: %{user_fixture() | authenticated_at: DateTime.utc_now(:second)}, conn: conn}
  end

  describe "log_in_api_user/3" do
    setup %{conn: conn} do
      %{conn: UserAuth.fetch_current_scope_for_user(conn, [])}
    end

    test "stores a session token", %{conn: conn, user: user} do
      conn = UserAuth.log_in_api_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert Accounts.get_user_by_session_token(token)
    end

    test "clears any prior session entries", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_api_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "keeps session when re-authenticating the same user", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> put_session(:to_be_removed, "value")
        |> UserAuth.log_in_api_user(user)

      assert get_session(conn, :to_be_removed)
    end

    test "writes the remember-me cookie when requested", %{conn: conn, user: user} do
      conn = conn |> fetch_cookies() |> UserAuth.log_in_api_user(user, %{"remember_me" => "true"})

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :user_remember_me) == true
      assert %{value: signed, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed != get_session(conn, :user_token)
      assert max_age == @remember_me_cookie_max_age
    end
  end

  describe "log_out_api_user/1" do
    test "clears session + remember-me cookie + DB token", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, token)
        |> put_req_cookie(@remember_me_cookie, token)
        |> fetch_cookies()
        |> UserAuth.fetch_current_scope_for_user([])
        |> UserAuth.log_out_api_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      refute Accounts.get_user_by_session_token(token)
    end

    test "is a no-op when already logged out", %{conn: conn} do
      conn =
        conn
        |> fetch_cookies()
        |> UserAuth.fetch_current_scope_for_user([])
        |> UserAuth.log_out_api_user()

      refute get_session(conn, :user_token)
    end
  end

  describe "fetch_current_scope_for_user/2" do
    test "authenticates a user via the session", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, token)
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert get_session(conn, :user_token) == token
    end

    test "authenticates a user via the remember-me cookie", %{conn: conn, user: user} do
      logged_in =
        conn
        |> fetch_cookies()
        |> UserAuth.fetch_current_scope_for_user([])
        |> UserAuth.log_in_api_user(user, %{"remember_me" => "true"})

      token = logged_in.cookies[@remember_me_cookie]
      %{value: signed} = logged_in.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed)
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert get_session(conn, :user_token) == token
      assert get_session(conn, :user_remember_me)
    end

    test "assigns a nil scope when there is no token", %{conn: conn} do
      conn = UserAuth.fetch_current_scope_for_user(conn, [])
      assert is_nil(conn.assigns.current_scope)
    end
  end
end
