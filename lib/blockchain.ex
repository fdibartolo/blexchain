defmodule Blexchain.Blockchain do
  @alphabet for n <- ?0..?Z, do: << n :: utf8 >>

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
end
