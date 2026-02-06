defmodule Tostada.World.Broadcasters.TestProbe do
  @moduledoc false

  @behaviour Tostada.World.Broadcaster

  @impl true
  def broadcast(payload) do
    case Process.whereis(:test_broadcaster_parent) do
      nil -> :ok
      pid -> send(pid, payload)
    end
  end
end
