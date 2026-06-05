defmodule TostadaWeb.Api.AuthController do
  @moduledoc """
  JSON auth endpoints. The client owns the UI; this module owns the
  password hashing, session cookie, and token issuance.
  """
  use TostadaWeb, :controller

  alias Tostada.Accounts
  alias TostadaWeb.UserAuth

  def register(conn, %{"email" => email, "password" => password, "display_name" => display_name} = params) do
    case Accounts.register_user(%{email: email, password: password, display_name: display_name}) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_api_user(user, params)
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

  def login(conn, %{"email" => email, "password" => password} = params) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials"})

      user ->
        conn
        |> UserAuth.log_in_api_user(user, params)
        |> json(%{user: safe_user(user)})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_params"})
  end

  def logout(conn, _params) do
    conn
    |> UserAuth.log_out_api_user()
    |> json(%{ok: true})
  end

  @doc """
  Initiate a password reset. Always responds 200 — the client can't tell
  whether the email existed, which avoids account enumeration. The
  caller-supplied `reset_url` is a template into which we substitute the
  reset token.
  """
  def forgot_password(conn, %{"email" => email} = params) do
    reset_url_template = Map.get(params, "reset_url", "/reset-password?token={token}")

    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(user, fn token ->
        String.replace(reset_url_template, "{token}", token)
      end)
    end

    json(conn, %{ok: true})
  end

  def forgot_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_params"})
  end

  @doc """
  Complete a password reset using the token from the reset email.
  """
  def reset_password(conn, %{"token" => token, "password" => password}) do
    case Accounts.get_user_by_reset_password_token(token) do
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_or_expired_token"})

      user ->
        case Accounts.reset_user_password(user, %{password: password}) do
          {:ok, _} ->
            json(conn, %{ok: true})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  def reset_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing_params"})
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
        # Some validators (e.g. unsafe_validate_unique) embed lists/atoms
        # in opts. Only interpolate scalars; other opts are diagnostic and
        # not user-facing.
        if scalar?(value) do
          String.replace(acc, "%{#{key}}", to_string(value))
        else
          acc
        end
      end)
    end)
  end

  defp scalar?(v) when is_binary(v) or is_number(v) or is_atom(v), do: true
  defp scalar?(_), do: false
end
