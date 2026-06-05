defmodule TostadaWeb.UserAuth do
  @moduledoc """
  Session helpers for the JSON API.

  Phoenix manages the session (HttpOnly cookie set by `Plug.Session` in
  the endpoint). The cookie holds a signed `:user_token` that points at a
  row in `users_tokens`. We use the cookie for browser HTTP requests.

  For non-cookie clients (e.g. Phoenix Channels handshake) the controller
  layer mints short-lived bearer tokens via `/api/socket-token` —
  `Phoenix.Token.sign/3` rather than session tokens.

  Pure HTML helpers from `phx.gen.auth` (`log_in_user`, `log_out_user`,
  `require_authenticated_user`, `redirect_if_user_is_authenticated`,
  `require_sudo_mode`) have been removed — auth UI is the client's
  responsibility. Controllers that need an authenticated user check
  `conn.assigns[:current_scope]` directly and return 401 JSON if absent.
  """

  import Plug.Conn

  alias Tostada.Accounts
  alias Tostada.Accounts.Scope

  # Remember-me cookie is valid for 14 days, matching the session token TTL.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_tostada_web_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # Reissue the session token after this many days. Lower = more inserts on
  # active users; higher = older tokens linger longer.
  @session_reissue_age_in_days 7

  @doc """
  Plug: load the current user (if any) into `:current_scope` from the
  session cookie or the remember-me cookie.

  Always assigns `:current_scope` (with `nil` user when unauthenticated)
  so downstream controllers can pattern-match without a `Map.has_key?`
  dance.
  """
  def fetch_current_scope_for_user(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> maybe_reissue_user_session_token(user, token_inserted_at)
    else
      _ -> assign(conn, :current_scope, Scope.for_user(nil))
    end
  end

  @doc """
  Logs the user in for an API request: mints a session token, stores it
  in the cookie-backed session, optionally writes the remember-me cookie.

  Returns the updated `conn`. The caller decides what JSON to send back
  (typically the freshly created/fetched user record).
  """
  def log_in_api_user(conn, user, params \\ %{}) do
    create_or_extend_session(conn, user, params)
  end

  @doc """
  Logs the user out: deletes the server-side session token, clears the
  cookie session, and clears the remember-me cookie.
  """
  def log_out_api_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    conn
    |> renew_session(user)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # If the same user is already logged in, don't renew the session — this
  # would CSRF-fail any in-flight tabs that haven't refreshed.
  defp renew_session(conn, user) when conn.assigns.current_scope.user.id == user.id do
    conn
  end

  defp renew_session(conn, _user) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => true}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    put_session(conn, :user_token, token)
  end
end
