defmodule Blexchain.GossipScheduler do
  use GenServer
  import IO.ANSI

  @http_client Application.get_env(:blexchain, :http_client)

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    if Mix.env != :test, do: schedule_work() 
    {:ok, state}
  end

  def handle_info(:work, state) do
    mined_blocks = get_mined_blocks ConCache.get(:blockchain, :blocks)
    ConCache.get(:blockchain, :ports)
      |> List.delete(System.get_env("PORT"))
      |> Enum.each(fn(p) -> @http_client.gossip_with_peer(p, ConCache.get(:blockchain, :ports), mined_blocks) end)

    render_state(ConCache.get(:blockchain, :ports), ConCache.get(:blockchain, :blocks))
    schedule_work() # Reschedule once again
    {:noreply, state}
  end

  defp get_mined_blocks(nil), do: []
  defp get_mined_blocks(blockchain), do: blockchain |> Enum.filter(fn(b) -> b.own_hash != nil end)

  defp schedule_work(), do: Process.send_after(self(), :work, 15 * 1000) # 15 secs

  defp render_state(_, nil), do: IO.puts "#{yellow()}#{italic()}Waiting to sync node...#{reset()}"
  defp render_state(peers, blockchain) do
    IO.puts "-> My Port: #{yellow()}#{System.get_env("PORT")}#{reset()}"
    my_peers = peers |> Enum.join(" - ")
    IO.puts "-> My Peers: #{green()}#{my_peers}#{reset()}"
    blocks = blockchain
      |> Enum.map(fn(b) -> "#{magenta()}\n     Prev: #{b.prev_block_hash}\n       Id: #{b.id}\n    Nonce: #{b.nonce}\n      Trx: #{b.transaction}\n      Own: #{b.own_hash}" end)
      |> Enum.join("#{reset()}\n    -----------------------------------↓-----------------------------------")
    IO.puts "-> My Blockchain: #{blocks}#{reset()}"
  end
end