defmodule PassTheChain do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(PassTheChain.UsernamesRegistry, []),
      supervisor(Registry, [:unique, PassTheChain.StoriesRegistry]),
      supervisor(PassTheChain.Endpoint, []),
      supervisor(PassTheChain.Presence, []),
    ]

    opts = [strategy: :one_for_one, name: PassTheChain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PassTheChain.Endpoint.config_change(changed, removed)
    :ok
  end
end
