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
      invalid_peer? from -> json (conn |> put_status(400)), "#{from} doesnt exist"
      invalid_peer? to -> json (conn |> put_status(400)), "#{to} doesnt exist"
      true -> Blexchain.Blockchain.add_to_chain(to, amount)
        |> case do
          {:error, status, msg} -> json (conn |> put_status(status)), msg
          {_, msg} -> json conn, msg
        end
    end
  end

  defp invalid_peer?(peer), do: ConCache.get(:blockchain, :ports) |> Enum.member?(peer) |> (&not(&1)).()

  def public_key(conn, %{}) do
    {status, value} = get_key ConCache.get(:blockchain, :public_key)
    json (conn|> put_status(status)), value 
  end

  defp get_key(nil), do: {422, "public key not set"}
  defp get_key(value), do: {200, value}
end
