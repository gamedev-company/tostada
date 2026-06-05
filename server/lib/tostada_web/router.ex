defmodule TostadaWeb.Router do
  use TostadaWeb, :router

  import TostadaWeb.UserAuth

  # JSON API with session-based auth (HttpOnly cookie from /api/auth/login)
  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
  end

  pipeline :require_admin do
    plug TostadaWeb.Plugs.RequireAdmin
  end

  # Pipeline for serving the SPA shell — no CSRF, no flash, just static HTML.
  pipeline :spa do
    plug :accepts, ["html"]
  end

  # SPA shell — serves index.html for any /app/* path. The client owns
  # routing from there; the client also checks /api/me on mount to decide
  # whether to render an unauthenticated or authenticated view.
  scope "/app", TostadaWeb do
    pipe_through :spa

    get "/", SpaController, :index
    get "/*path", SpaController, :index
  end

  # Authenticated API routes
  scope "/api", TostadaWeb.Api do
    pipe_through :api

    get "/me", UserController, :me
    get "/socket-token", UserController, :socket_token
  end

  # Auth endpoints — accept JSON, set HttpOnly session cookie on login/register
  scope "/api/auth", TostadaWeb.Api do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
    post "/forgot-password", AuthController, :forgot_password
    post "/reset-password", AuthController, :reset_password
  end

  ## Dev-only routes
  if Application.compile_env(:tostada, :dev_routes) do
    scope "/dev" do
      pipe_through :spa

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
