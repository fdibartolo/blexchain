defmodule Blexchain.Validator do
  # proxy method the all validators within the module
  def valid_blockchain?(blockchain) when is_list(blockchain) do
    Enum.reduce(blockchain, true, fn(b, acc) -> valid?(b) and acc end) and valid?(blockchain)
  end

  def valid?(:genesis, _txn, _signature), do: true
  def valid?(from, txn, signature), do: Blexchain.RSA.valid_signature?(txn, signature, from)

  def valid?(block) when is_map(block) do
    message = [block.from, block.to, block.amount, block.prev_block_hash] |> Enum.join
    valid?(block.from, block.transaction, block.signature) and case block.own_hash do
      nil -> false
      _ -> Blexchain.Blockchain.valid_nonce?(message, block.nonce)
    end    
  end

  def valid?(blockchain) when is_list(blockchain) do
    valid_hashes?(blockchain) and blockchain |> spends_valid?
  end

  defp valid_hashes?(blockchain) do
    blockchain
      |> Enum.chunk_every(2,1,:discard)
      |> Enum.reduce(true, fn(pair, acc) -> hashes_match?(pair) and acc end)    
  end

  defp hashes_match?([p, a]), do: Map.fetch!(p, :own_hash) == Map.fetch!(a, :prev_block_hash)

  defp spends_valid?([genesis_block|blocks]) do
    balances = %{genesis_block.to => genesis_block.amount}
    case compute_balances(blocks, balances) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp compute_balances([], balances), do: {:ok, balances}

  defp compute_balances([block|blocks], balances) do
    updated_balances = balances
      |> Map.update(block.to, block.amount, &(&1 + block.amount))
      |> Map.update!(block.from, &(&1 - block.amount))

    case updated_balances |> Map.values |> valid_amounts? do
      true -> compute_balances(blocks, updated_balances)
      false -> {:error, updated_balances}
    end
  end

  defp valid_amounts?(amounts), do: !Enum.any?(amounts, fn(a) -> a < 0 end)
end
