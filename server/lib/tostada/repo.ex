defmodule Tostada.Repo do
  use Ecto.Repo,
    otp_app: :tostada,
    adapter: Ecto.Adapters.Postgres
end
