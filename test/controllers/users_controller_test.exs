defmodule Blexchain.UsersControllerTest do
  use Blexchain.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  # setup do
  #   Supervisor.terminate_child(Blexchain, ConCache)
  #   Supervisor.restart_child(Blexchain, ConCache)
  #   :ok
  # end

  describe "transfer" do
    test "unable to transfer negtive amount", %{conn: conn} do
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => -10, "from" => nil, "to" => nil}
      assert json_response(conn, 400) |> String.starts_with?("Cannot transfer this amount")
    end

    test "unable to transfer when from user does not exist", %{conn: conn} do
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "1234", "to" => nil}
      assert json_response(conn, 400) |> String.starts_with?("1234 doesnt exist")
    end

    test "unable to transfer when to user does not exist", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000"])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "1234"}
      assert json_response(conn, 400) |> String.starts_with?("1234 doesnt exist")
    end

    test "able to transfer succesfully between users", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000","4001"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "4000", amount: 100, own_hash: "ABCD"}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "4001"}
      assert json_response(conn, 200) |> String.starts_with?("Transaction block added, to be mined soon to assert validity")
      assert length(ConCache.get(:blockchain, :blocks)) == 2
    end

    test "transfer succesfully and prev block own hash equals new block prev hash", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000","4001"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "4000", amount: 100, own_hash: "ABCD"}])
      post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "4001"}
      new_block = ConCache.get(:blockchain, :blocks) |> List.last
      assert new_block.prev_block_hash == "ABCD"
    end
  end

  describe "public_key" do
    test "return 422 when key is not present in cache", %{conn: conn} do
      ConCache.put(:blockchain, :public_key, nil)
      conn = get conn, public_key_path(conn, :public_key)
      assert json_response(conn, 422) |> String.starts_with?("public key not set")
    end

    test "return the key value when it exists in cache", %{conn: conn} do
      ConCache.put(:blockchain, :public_key, "my public key")
      conn = get conn, public_key_path(conn, :public_key)
      assert json_response(conn, 200) |> String.starts_with?("my public key")
    end
  end
end
