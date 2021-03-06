defmodule Blexchain.BlockchainTest do
  use ExUnit.Case

  @block %{
    prev_block_hash: "SOME HASH", 
    from: "4000", 
    to: "4001", 
    amount: 100,
    nonce: nil,
    own_hash: nil
  }
  @pow_zeroes Application.get_env(:blexchain, :pow_zeroes)

  test "finding nonce generates hash with 3 leading zeroes and 64 chars long" do
    {_nonce, hash} = Blexchain.Blockchain.find_nonce(@block)
    assert hash |> String.starts_with?(@pow_zeroes)
    assert hash |> String.length == 64
  end

  test "mined block has a valid own hash" do
    ConCache.put(:blockchain, :blocks, [@block])
    mined_block = Blexchain.Blockchain.mine_block! @block
    assert mined_block.own_hash |> String.starts_with?(@pow_zeroes)
  end

  test "unable to add new block when previous hasnt been mined yet" do
    ConCache.put(:blockchain, :blocks, [@block])
    {status, _, msg} = Blexchain.Blockchain.add_to_chain("4001", 50)
    assert status == :error
    assert msg |> String.starts_with?("Previous block hasnt been mined yet")
  end

  test "able to add new block to the chain" do
    block = @block |> Map.update!(:own_hash, fn(_) -> "OWN_HASH" end)
    ConCache.put(:blockchain, :blocks, [block])
    {status, msg} = Blexchain.Blockchain.add_to_chain("4001", 50)
    assert status == :ok
    assert msg |> String.starts_with?("Block added successfully")
  end

  test "newly added block prev hash equals previous block own hash" do
    block = @block |> Map.update!(:own_hash, fn(_) -> "OWN_HASH" end)
    ConCache.put(:blockchain, :blocks, [block])
    Blexchain.Blockchain.add_to_chain("4001", 50)
    new_block = ConCache.get(:blockchain, :blocks) |> List.last
    assert new_block.prev_block_hash == block.own_hash
  end

  test "able to build genesis block" do
    assert Blexchain.Blockchain.build_genesis_block() |> Map.fetch!(:from) == :genesis
  end
end
