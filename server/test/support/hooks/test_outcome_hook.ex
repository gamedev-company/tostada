defmodule Tostada.Tasks.TestOutcomeHook do
  @moduledoc false

  @behaviour Tostada.Tasks.OutcomeHook

  @impl true
  def handle(event) do
    case Process.whereis(:test_outcome_hook_parent) do
      nil -> :ok
      pid -> send(pid, {:outcome_event, event})
    end
  end
end
