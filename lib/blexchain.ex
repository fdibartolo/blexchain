defmodule Blexchain do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Blexchain.Endpoint, []),
      # Start your own worker by calling: Blexchain.Worker.start_link(arg1, arg2, arg3)
      # worker(Blexchain.Worker, [arg1, arg2, arg3]),
      
      # create in-memory storage to keep peers and blocks within the network
      supervisor(ConCache, [[], [name: :blockchain]]),

      # schedule sync up nodes
      worker(Blexchain.GossipScheduler, []),

      # schedule mine own blocks
      worker(Blexchain.MineScheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blexchain.Supervisor]
    start_status = Supervisor.start_link(children, opts)

    initialize_cache()

    start_status
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Blexchain.Endpoint.config_change(changed, removed)
    :ok
  end

  defp initialize_cache do
    {private_key, public_key} = Blexchain.RSA.generate_key_pair
    ConCache.put(:blockchain, :public_key, public_key)
    ConCache.put(:blockchain, :private_key, private_key)

    if System.get_env("PEER") == nil do
      ConCache.put(:blockchain, :blocks, [Blexchain.Blockchain.build_genesis_block()])
      ConCache.put(:blockchain, :peers, [Application.get_env(:blexchain, :host_ip)])
    else
      ConCache.put(:blockchain, :peers, [Application.get_env(:blexchain, :host_ip), System.get_env("PEER")])
    end
  end
end
