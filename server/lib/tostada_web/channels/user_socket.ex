defmodule TostadaWeb.UserSocket do
  use Phoenix.Socket

  alias Tostada.Accounts

  # Channels
  channel "app:*", TostadaWeb.AppChannel

  @doc """
  Socket authentication.

  Supports two authentication methods:
  1. Session-based (for web clients) - uses session token from cookie
  2. Token-based (for native clients) - uses Phoenix.Token

  Returns `{:ok, socket}` with user_id assigned on success.
  """
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # Token-based auth for native clients
    case Phoenix.Token.verify(TostadaWeb.Endpoint, "user socket", token, max_age: 86400) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, socket, connect_info) do
    # Session-based auth for web clients
    case get_session_token(connect_info) do
      nil ->
        :error

      token ->
        case Accounts.get_user_by_session_token(token) do
          {user, _inserted_at} ->
            {:ok, assign(socket, :user_id, user.id)}

          nil ->
            :error
        end
    end
  end

  defp get_session_token(connect_info) do
    case Map.get(connect_info, :session) do
      nil -> nil
      session -> Map.get(session, "user_token")
    end
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
