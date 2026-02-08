defmodule TostadaWeb.Presence do
  @moduledoc """
  Presence tracker for realtime app state.
  """

  use Phoenix.Presence,
    otp_app: :tostada,
    pubsub_server: Tostada.PubSub
end
