defmodule Blexchain.Blockchain do
  @alphabet for n <- ?0..?Z, do: << n :: utf8 >>
  @http_client Application.get_env(:blexchain, :http_client)

  def mine_block!(block) do
    {_nonce, hash} = find_nonce(block)
    block |> Map.update(:own_hash, nil, fn(_) -> hash end)
  end

  def find_nonce(block) do
    message = [block.from, block.to, block.amount] |> Enum.join |> hash
    find_nonce(message, "startup nonce", false)
  end

  defp find_nonce(message, nonce, true), do: {nonce, nonce |> (&message <> &1).() |> hash}

  defp find_nonce(message, _nonce, _valid) do
    n = next_nonce()
    find_nonce(message, n, valid_nonce?(message, n))
  end

  defp valid_nonce?(message, nonce) do
    nonce
      |> (&message <> &1).()
      |> hash
      |> String.starts_with?("000")
  end

  def hashed_transaction_for(%{from: from, amount: amt}, to), do: [from,amt,to] |> Enum.join |> hash

  defp hash(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16

  defp next_nonce() do
    1..32
      |> Enum.reduce([], fn(_, acc) -> [Enum.random(@alphabet) | acc] end)
      |> Enum.join("")
  end

  def add_to_chain(to, amount) do
    prev_block_hash = ConCache.get(:blockchain, :blocks)
      |> List.last |> Map.fetch(:own_hash) |> elem(1)

    public_key = ConCache.get(:blockchain, :public_key)
    private_key = ConCache.get(:blockchain, :private_key)

    peer_public_key = @http_client.public_key_of(to)
    trx = hashed_transaction_for(%{from: public_key, amount: amount}, peer_public_key)
    signature = trx |> Blexchain.RSA.sign(private_key)

    added = ConCache.update(:blockchain, :blocks, fn(b) ->
      block = %{
        id: UUID.uuid1(),
        prev_block_hash: prev_block_hash,
        from: public_key,
        to: peer_public_key,
        amount: amount,
        transaction: trx,
        signature: signature,
        own_hash: nil
      }

      blocks = b |> List.insert_at(-1, block)
      {:ok, blocks}
    end)

    cond do
      prev_block_hash == nil -> {:error, 422, "Previous block hasnt been mined yet, try again in a few seconds"}
      added != :ok -> {:error, 500, "Oops, something went wrong! Block could not be added to blockchain"}
      true -> {:ok, "Block added successfully. It will be mined soon to assert validity"}
    end
  end
end
