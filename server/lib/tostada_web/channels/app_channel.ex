defmodule TostadaWeb.AppChannel do
  @moduledoc """
  Minimal authenticated channel for real-time app events.
  """

  use TostadaWeb, :channel

  @impl true
  def join("app:lobby", _payload, socket) do
    {:ok, socket}
  end

  def join("app:" <> _subtopic, _payload, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, Map.put(payload, "at", DateTime.utc_now())}, socket}
  end

  def handle_in("whoami", _payload, socket) do
    {:reply, {:ok, %{user_id: socket.assigns.user_id}}, socket}
  end
end
