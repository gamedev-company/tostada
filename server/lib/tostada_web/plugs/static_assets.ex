defmodule TostadaWeb.Plugs.StaticAssets do
  @moduledoc """
  Serves large static assets from the /obj folder.

  These assets (GLTF models, audio, etc.) are synced separately via rsync
  and not included in phx.digest to avoid duplication.
  """

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{request_path: "/obj/" <> _} = conn, _opts) do
    case obj_path() do
      nil ->
        conn

      path ->
        opts =
          Plug.Static.init(
            at: "/obj",
            from: path,
            gzip: false,
            cache_control_for_etags: "public, max-age=31536000"
          )

        Plug.Static.call(conn, opts)
    end
  end

  def call(conn, _opts), do: conn

  defp obj_path do
    Application.get_env(:tostada, :obj_path)
  end
end
