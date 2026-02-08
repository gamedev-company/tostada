defmodule TostadaWeb.Api.AuthController do
  use TostadaWeb, :controller

  alias Tostada.Accounts

  def register(conn, %{"email" => email, "password" => password, "display_name" => display_name}) do
    case Accounts.register_user(%{email: email, password: password, display_name: display_name}) do
      {:ok, user} ->
        conn
        |> log_in_for_api(user)
        |> json(%{user: safe_user(user)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  def register(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_params"})
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials"})

      user ->
        conn
        |> log_in_for_api(user)
        |> json(%{user: safe_user(user)})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_params"})
  end

  def logout(conn, _params) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> json(%{ok: true})
  end

  defp log_in_for_api(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:user_token, token)
  end

  defp safe_user(user) do
    %{
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      is_admin: user.is_admin
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
