defmodule Blexchain.Blockchain do
  @alphabet for n <- ?0..?Z, do: << n :: utf8 >>
  @http_client Application.get_env(:blexchain, :http_client)

  def mine_block!(block) do
    {nonce, hash} = find_nonce(block)
    block
      |> Map.update!(:own_hash, fn(_) -> hash end)
      |> Map.update!(:nonce, fn(_) -> nonce end)
  end

  def find_nonce(block) do
    message = [block.from, block.to, block.amount, block.prev_block_hash] |> Enum.join
    find_nonce(message, "startup nonce", false)
  end

  defp find_nonce(message, nonce, true), do: {nonce, nonce |> (&message <> &1).() |> hash}

  defp find_nonce(message, _nonce, _valid) do
    n = next_nonce()
    find_nonce(message, n, valid_nonce?(message, n))
  end

  def valid_nonce?(message, nonce) do
    nonce
      |> (&message <> &1).()
      |> hash
      |> String.starts_with?("000")
  end

  defp hash(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16

  defp next_nonce() do
    1..32
      |> Enum.reduce([], fn(_, acc) -> [Enum.random(@alphabet) | acc] end)
      |> Enum.join("")
  end

  def add_to_chain(to, amount) do
    ConCache.get(:blockchain, :blocks)
      |> List.last |> Map.fetch(:own_hash) |> elem(1)
      |> update_cache(to, amount)
  end

  defp update_cache(nil, _, _), do: {:error, 422, "Previous block hasnt been mined yet, try again in a few seconds"}
  defp update_cache(prev_block_hash, to, amount) do
    block = build_block(to, amount)
      |> Map.update!(:prev_block_hash, fn(_) -> prev_block_hash end)

    ConCache.update(:blockchain, :blocks, fn(b) ->
      blocks = b |> List.insert_at(-1, block)
      {:ok, blocks}
    end) |> case do
      :ok -> {:ok, "Block added successfully. It will be mined soon to assert validity"}
      _ -> {:error, 500, "Oops, something went wrong! Block could not be added to blockchain"}
    end
  end

  def build_block(to, amount) do
    peer_public_key = @http_client.public_key_of(to)
    build_block_with(ConCache.get(:blockchain, :public_key), peer_public_key, amount)
  end

  def build_genesis_block() do
    build_block_with(:genesis, ConCache.get(:blockchain, :public_key), 500_000)
  end

  defp build_block_with(from, to, amount) do
    trx = [from,to,amount] |> Enum.join |> hash
    signature = trx |> Blexchain.RSA.sign(ConCache.get(:blockchain, :private_key))

    %{
      id: UUID.uuid1(), prev_block_hash: nil, from: from, to: to, amount: amount,
      nonce: nil, transaction: trx, signature: signature, own_hash: nil
    }    
  end
end
