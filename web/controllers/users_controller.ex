defmodule Blexchain.UsersController do
  use Blexchain.Web, :controller

  def gossip(conn, %{"peers" => p, "blockchain" => b}) do
    peer_ports = ConCache.get(:blockchain, :ports) ++ p
      |> Enum.uniq

    case newer_blockchain?(b) do 
      {true, value} -> ConCache.put(:blockchain, :blocks, value)
      {false, _} -> "Blockchain up to date"
    end

    case ConCache.put(:blockchain, :ports, peer_ports) do
      :ok -> json conn, "Ok!"
      _ -> json (conn |> put_status(500)), "Something went wrong!"
    end
  end

  defp newer_blockchain?(blockchain) when blockchain == nil, do: {false, nil}
  defp newer_blockchain?(blockchain) do
    parsed = blockchain
      |> Poison.encode!
      |> Poison.Parser.parse!(keys: :atoms!)

    cond do
      ConCache.get(:blockchain, :blocks) == nil -> {true, parsed}
      ConCache.get(:blockchain, :blocks) == parsed -> {false, nil}
      true -> {length(parsed) > length(ConCache.get(:blockchain, :blocks)), parsed}
    end
  end

  def transfer(conn, %{"from" => from, "to" => to, "amount" => amount}) do
    cond do
      amount <= 0 -> json (conn |> put_status(400)), "Cannot transfer this amount; it must be greater than 0"
      peer_exist? from -> json (conn |> put_status(400)), "#{from} doesnt exist"
      peer_exist? to -> json (conn |> put_status(400)), "#{to} doesnt exist"
      true -> add_block_to_chain(from, to, amount); json conn, "Transaction block added, to be mined soon to assert validity"
    end
  end

  defp peer_exist?(peer), do: ConCache.get(:blockchain, :ports) |> Enum.member?(peer) |> (&not(&1)).()

  defp add_block_to_chain(from, to, amount) do
    prev_block = ConCache.get(:blockchain, :blocks) |> List.last
    ConCache.update(:blockchain, :blocks, fn(b) ->
      block = %{
        id: UUID.uuid1(),
        prev_block_hash: prev_block.own_hash,
        from: from,
        to: to,
        amount: amount,
        own_hash: nil
      }

      blocks = b |> List.insert_at(-1, block)
      {:ok, blocks}
    end)
  end
end
