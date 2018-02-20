defmodule Blexchain.BlockchainTest do
  use ExUnit.Case

  @block %{
    id: 1234,
    prev_block_hash: "SOME HASH", 
    from: "4000", 
    to: "4001", 
    amount: 100,
    own_hash: nil
  }

  test "finding nonce generates hash with 3 leading zeroes and 64 chars long" do
    {_nonce, hash} = Blexchain.Blockchain.find_nonce(@block)
    assert hash |> String.starts_with?("000")
    assert hash |> String.length == 64
  end

  test "mined block has a valid own hash" do
    ConCache.put(:blockchain, :blocks, [@block])
    mined_block = Blexchain.Blockchain.mine_block! @block
    assert mined_block.own_hash |> String.starts_with?("000")
  end
end
