import Config

# Configure your database
config :tostada, Tostada.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "tostada_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable debugging.
config :tostada, TostadaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "DElqIPpHr0wGbPSHe9ViXFBeSO4PBXDo+r4d/Ro7XZI/eEo9VxkBH1rdJPE0xl3F"

# Enable dev routes for the Swoosh mailbox preview at /dev/mailbox
config :tostada, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Large assets folder (GLTF, audio, etc.)
config :tostada, obj_path: Path.expand("../obj", __DIR__)
