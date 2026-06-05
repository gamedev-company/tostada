defmodule TostadaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, channels, and so on.

  This can be used in your application as:

      use TostadaWeb, :controller
      use TostadaWeb, :channel

  This project is API + WebSocket only — no LiveView, no HTML rendering
  outside of the SPA shell served by `TostadaWeb.SpaController`. The
  `:html`, `:live_view`, and `:live_component` use macros from the
  generator template have been removed accordingly.
  """

  def static_paths, do: ~w(app favicon.svg robots.txt images)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: TostadaWeb.Endpoint,
        router: TostadaWeb.Router,
        statics: TostadaWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/channel/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
