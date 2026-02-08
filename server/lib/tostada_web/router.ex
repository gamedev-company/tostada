defmodule TostadaWeb.Router do
  use TostadaWeb, :router

  import TostadaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TostadaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # API with session auth (for SPA clients)
  pipeline :api_auth do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
  end

  pipeline :require_admin do
    plug TostadaWeb.Plugs.RequireAdmin
  end

  scope "/", TostadaWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # SPA routes - require authentication, then serve the SvelteKit app
  scope "/app", TostadaWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Catch-all for client-side routing
    get "/", SpaController, :index
    get "/*path", SpaController, :index
  end

  # API routes with session auth
  scope "/api", TostadaWeb.Api do
    pipe_through :api_auth

    get "/me", UserController, :me
    get "/socket-token", UserController, :socket_token
  end

  scope "/api/auth", TostadaWeb.Api do
    pipe_through :api_auth

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tostada, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TostadaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Admin routes

  scope "/admin", TostadaWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live "/", UserLive.Index, :index
    live "/users", UserLive.Index, :index
    live "/users/:id/edit", UserLive.Index, :edit
  end

  ## Authentication routes

  scope "/", TostadaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", TostadaWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", TostadaWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
    get "/users/confirm/:token", UserConfirmationController, :show
  end
end
