defmodule TostadaWeb.UserConfirmationController do
  use TostadaWeb, :controller

  alias Tostada.Accounts

  def show(conn, %{"token" => token}) do
    case Accounts.confirm_user_by_token(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User confirmed successfully. You can now log in.")
        |> redirect(to: ~p"/users/log-in")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end
end
