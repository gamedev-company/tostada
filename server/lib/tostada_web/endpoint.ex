defmodule TostadaWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :tostada

  # The session is signed (not encrypted) and stored in an HttpOnly cookie.
  @session_options [
    store: :cookie,
    key: "_tostada_key",
    signing_salt: "gbRco5OR",
    same_site: "Lax"
  ]

  # Phoenix Channels socket. The browser presents a short-lived token
  # fetched from /api/socket-token to authenticate; the cookie is also
  # accepted as a fallback for same-origin clients.
  socket "/socket", TostadaWeb.UserSocket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  # Serve large assets from /obj (synced separately, not digested).
  # These are GLTF models, audio files, etc.
  plug TostadaWeb.Plugs.StaticAssets

  # Serve client model assets from /models (built by the SvelteKit-Threlte
  # variant's model pipeline).
  plug Plug.Static,
    at: "/models",
    from: {:tostada, "priv/static/app/models"},
    gzip: false

  # Serve at "/" the static files from "priv/static" — limited to the
  # SPA shell, favicon, robots.txt, and shared images.
  plug Plug.Static,
    at: "/",
    from: :tostada,
    gzip: not code_reloading?,
    only: TostadaWeb.static_paths()

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # CORS for development (Vite client on a different port)
  if Mix.env() == :dev do
    plug TostadaWeb.Plugs.Cors
  end

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TostadaWeb.Router
end
