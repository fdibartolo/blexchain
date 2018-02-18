defmodule Blexchain.Scheduler do
  use GenServer
  import IO.ANSI

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    ConCache.get(:nodes, :ports)
      |> List.delete(System.get_env("PORT"))
      |> Enum.each(fn(p) -> Blexchain.Client.gossip_nodes(p, ConCache.get(:nodes, :ports)) end)

    render_state()
    schedule_work() # Reschedule once again
    {:noreply, state}
  end

  defp schedule_work() do
    # Process.send_after(self(), :work, 2 * 60 * 60 * 1000) # In 2 hours
    Process.send_after(self(), :work, 3 * 1000) # In 3 sec
  end

  defp render_state() do
    IO.puts "#{reset()} My Port: #{yellow()}#{System.get_env("PORT")}"
    peers = ConCache.get(:nodes, :ports) |> Enum.join(" - ")
    IO.puts "#{reset()} My Peers: #{green()}#{peers}"
  end
end