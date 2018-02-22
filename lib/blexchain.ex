defmodule Blexchain do
  use Application

  @genesis_block %{
    id: UUID.uuid1(),
    prev_block_hash: nil, 
    from: :genesis, 
    to: nil, 
    amount: 500_000,
    transaction: nil,
    signature: nil,
    own_hash: nil
  }

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    if System.get_env("PORT") == nil, do: IO.puts "PORT is not set! Do so at start up via 'PORT=4000 mix phx.server'"

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Blexchain.Endpoint, []),
      # Start your own worker by calling: Blexchain.Worker.start_link(arg1, arg2, arg3)
      # worker(Blexchain.Worker, [arg1, arg2, arg3]),
      
      # create in-memory storage to keep peer ports and blocks within the network
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
      # create genesis block
      trx = Blexchain.Blockchain.hashed_transaction_for(@genesis_block, public_key)
      signature = trx |> Blexchain.RSA.sign(private_key)

      block = @genesis_block
        |> Map.update!(:to, fn(_) -> public_key end)
        |> Map.update!(:transaction, fn(_) -> trx end)
        |> Map.update!(:signature, fn(_) -> signature end)
      ConCache.put(:blockchain, :blocks, [block])

      ConCache.put(:blockchain, :ports, [System.get_env("PORT")])
    else
      ConCache.put(:blockchain, :ports, [System.get_env("PORT"), System.get_env("PEER")])
    end
  end
end
