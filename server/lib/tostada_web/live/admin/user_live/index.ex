defmodule TostadaWeb.Admin.UserLive.Index do
  use TostadaWeb, :live_view

  alias Tostada.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :users, Accounts.list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({TostadaWeb.Admin.UserLive.Form, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, stream_delete(socket, :users, user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Users
      </.header>

      <.table
        id="users"
        rows={@streams.users}
        row_click={fn {_id, user} -> JS.navigate(~p"/admin/users/#{user}/edit") end}
      >
        <:col :let={{_id, user}} label="Email">{user.email}</:col>
        <:col :let={{_id, user}} label="Display Name">{user.display_name}</:col>
        <:col :let={{_id, user}} label="Admin">
          <span class={if user.is_admin, do: "text-green-600 font-medium", else: "text-zinc-400"}>
            {if user.is_admin, do: "Yes", else: "No"}
          </span>
        </:col>
        <:col :let={{_id, user}} label="Confirmed">
          <span class={if user.confirmed_at, do: "text-green-600", else: "text-amber-600"}>
            {if user.confirmed_at, do: "Yes", else: "No"}
          </span>
        </:col>
        <:action :let={{_id, user}}>
          <div class="sr-only">
            <.link navigate={~p"/admin/users/#{user}/edit"}>Show</.link>
          </div>
          <.link patch={~p"/admin/users/#{user}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, user}}>
          <.link
            phx-click={JS.push("delete", value: %{id: user.id}) |> hide("##{id}")}
            data-confirm="Are you sure? This will delete the user and all their data."
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal
        :if={@live_action == :edit}
        id="user-modal"
        show
        on_cancel={JS.patch(~p"/admin/users")}
      >
        <.live_component
          module={TostadaWeb.Admin.UserLive.Form}
          id={@user.id}
          title={@page_title}
          action={@live_action}
          user={@user}
          patch={~p"/admin/users"}
        />
      </.modal>
    </Layouts.app>
    """
  end
end
