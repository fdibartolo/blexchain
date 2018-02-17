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

      # create in-memory storage to keep user balances
      supervisor(ConCache, [[], [name: :balances]])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blexchain.Supervisor]
    start_status = Supervisor.start_link(children, opts)

    ConCache.put(:balances, "genesis", 1_000_000)
    start_status
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Blexchain.Endpoint.config_change(changed, removed)
    :ok
  end
end
