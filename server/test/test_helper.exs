ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Tostada.Repo, :manual)

unless Code.ensure_loaded?(Tostada.World.Broadcasters.TestProbe) do
  Code.require_file("support/broadcasters/test_probe.ex", __DIR__)
end

unless Code.ensure_loaded?(Tostada.Tasks.TestOutcomeHook) do
  Code.require_file("support/hooks/test_outcome_hook.ex", __DIR__)
end
