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
    ConCache.get(:blockchain, :ports)
      |> List.delete(System.get_env("PORT"))
      |> Enum.each(fn(p) -> Blexchain.Client.gossip_with_peer(p, ConCache.get(:blockchain, :ports), ConCache.get(:blockchain, :blocks)) end)

    render_state(ConCache.get(:blockchain, :ports), ConCache.get(:blockchain, :blocks))
    schedule_work() # Reschedule once again
    {:noreply, state}
  end

  defp schedule_work(), do: Process.send_after(self(), :work, 5 * 1000) # 5 secs

  defp render_state(_, nil), do: IO.puts "#{yellow()}#{italic()}syncing...#{reset()}"
  defp render_state(peers, blockchain) do
    IO.puts "-> My Port: #{yellow()}#{System.get_env("PORT")}#{reset()}"
    my_peers = peers |> Enum.join(" - ")
    IO.puts "-> My Peers: #{green()}#{my_peers}#{reset()}"
    blocks = blockchain
      |> Enum.map(fn(b) -> "From: #{b.from} - To: #{b.to} - Amount: #{b.amount}" end)
      |> Enum.join("\n")
    IO.puts "-> My Blockchain: #{magenta()}#{blocks}#{reset()}"
  end
end