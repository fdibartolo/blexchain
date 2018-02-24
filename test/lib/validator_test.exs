defmodule Blexchain.ValidatorTest do
  use ExUnit.Case

  @block Blexchain.Blockchain.build_block("4001", 1000)

  describe "transaction" do
    test "valid for the genesis transaction" do
      assert Blexchain.Validator.valid?(:genesis, "TXN", "SIGNATURE")
    end

    test "invalid when data is hacked after signed" do
      block = @block |> Map.update!(:transaction, fn(_) -> "INFO_IS_HACKED" end)
      refute Blexchain.Validator.valid?(block.from, block.transaction, block.signature)
    end

    test "valid when properly signed with key" do
      assert Blexchain.Validator.valid?(@block.from, @block.transaction, @block.signature)
    end
  end

  describe "block" do
    test "invalid for nil own hash" do
      refute Blexchain.Validator.valid?(@block)
    end

    test "invalid when data is hacked after mined" do
      mined_block = @block |> Blexchain.Blockchain.mine_block!
      assert mined_block.own_hash |> String.starts_with?("000")
      refute mined_block 
        |> Map.update!(:nonce, fn(_) -> "SOME_NONCE" end)
        |> Blexchain.Validator.valid?
    end

    test "valid when properly mined" do
      assert @block |> Blexchain.Blockchain.mine_block! |> Blexchain.Validator.valid?
    end
  end

  describe "blockchain" do
    test "invalid when prev and own hash of a pair of consecutive blocks are not equal" do
      genesis_block = Blexchain.Blockchain.build_genesis_block()
        |> Map.update!(:own_hash, fn(_) -> "000_SOME_HASH" end)
      block = @block |> Map.update!(:prev_block_hash, fn(_) -> "RANDOM_VALUE" end)
      refute Blexchain.Validator.valid?([genesis_block, block])
    end

    test "invalid when transfering insufficient funds" do
      genesis_block = Blexchain.Blockchain.build_genesis_block()
        |> Map.update!(:own_hash, fn(_) -> "000_SOME_HASH" end)
      block = Blexchain.Blockchain.build_block("4001", 500_001)
        |> Map.update!(:prev_block_hash, fn(_) -> "000_SOME_HASH" end)
      refute Blexchain.Validator.valid?([genesis_block, block])
    end

    test "valid when prev and own hash of a pair of consecutive blocks are equal and sufficient funds" do
      genesis_block = Blexchain.Blockchain.build_genesis_block()
        |> Map.update!(:own_hash, fn(_) -> "000_SOME_HASH" end)
      block = @block |> Map.update!(:prev_block_hash, fn(_) -> "000_SOME_HASH" end)
      assert Blexchain.Validator.valid?([genesis_block, block])
    end
  end
end
