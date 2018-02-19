defmodule Blexchain do
  use Application

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

      # create in-memory storage to keep user balances
      # supervisor(ConCache, [[], [name: :balances]]),
      
      # create in-memory storage to keep peer ports within the network
      supervisor(ConCache, [[], [name: :blockchain]]),

      # schedule sync up nodes
      worker(Blexchain.Scheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blexchain.Supervisor]
    start_status = Supervisor.start_link(children, opts)

    # ConCache.put(:balances, "genesis", 1_000_000)

    ConCache.put(:blockchain, :ports, [System.get_env("PORT")])

    if System.get_env("PEER") == nil do
      # create genesis block
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: System.get_env("PORT"), amount: 500_000}])
    else
      ConCache.update(:blockchain, :ports, fn(p) ->
        ports = p |> List.insert_at(-1, System.get_env("PEER"))
        {:ok, ports}
      end)
    end

    start_status
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Blexchain.Endpoint.config_change(changed, removed)
    :ok
  end
end
