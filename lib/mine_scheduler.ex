defmodule Blexchain.MineScheduler do
  use GenServer
  import IO.ANSI

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    if Mix.env != :test, do: schedule_work() 
    {:ok, state}
  end

  def handle_info(:work, state) do
    ConCache.get(:blockchain, :blocks)
      |> first_unmined_block
      |> mine_block
      |> case do
        {:ok, mined_block} -> validate_blockchain_with(mined_block)
        {:no_action, _} -> "No block needs to be mined"
      end

    schedule_work() # Reschedule once again
    {:noreply, state}
  end

  defp schedule_work(), do: Process.send_after(self(), :work, 4 * 1000) # 4 secs

  defp first_unmined_block(nil), do: nil
  defp first_unmined_block(blocks), do: blocks |> Enum.find(fn(b) -> b.own_hash == nil end)

  defp mine_block(nil), do: {:no_action, nil}
  defp mine_block(block) do
    IO.puts "-> #{green()}Mining new block...#{reset()}"
    {:ok, Blexchain.Blockchain.mine_block!(block)}
  end

  defp validate_blockchain_with(mined_block) do
    blockchain = ConCache.get(:blockchain, :blocks)
      |> Enum.filter(fn(b) -> b.id != mined_block.id end)
      |> Enum.concat([mined_block])

    blockchain
      |> Blexchain.Validator.valid?
      |> case do
        true -> ConCache.put(:blockchain, :blocks, blockchain)
        false -> remove_from_blockchain(mined_block)
      end
  end

  defp remove_from_blockchain(block) do
    IO.puts "-> #{red()}#{bright()}Recent mined block invalidates the blockchain, it is now being destroyed!#{reset()}"

    ConCache.get(:blockchain, :blocks)
      |> Enum.filter(fn(b) -> b.id != block.id end)
      |> (&ConCache.put(:blockchain, :blocks, &1)).()
  end
end