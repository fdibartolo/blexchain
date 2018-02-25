defmodule Blexchain.UsersControllerTest do
  use Blexchain.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "gossip" do
    test "update own peer ports given peer node", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000"])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["4001"], "blockchain" => nil}
      assert ConCache.get(:blockchain, :ports) |> Enum.member?("4001")
    end

    test "keep own blockchain when peer blockchain is nil", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000"])
      ConCache.put(:blockchain, :blocks, [%{id: 123, from: nil, to: "4000", amount: 100}])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["4001"], "blockchain" => nil}
      blockchain = ConCache.get(:blockchain, :blocks)
      assert length(blockchain) == 1
      assert blockchain |> List.first |> Map.fetch!(:id) == 123
    end

    test "keep peer blockchain when own is nil", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000"])
      ConCache.put(:blockchain, :blocks, nil)
      post conn, gossip_path(conn, :gossip), %{"peers" => ["4001"], "blockchain" => [%{id: 234, from: nil, to: "4001", amount: 100}]}
      blockchain = ConCache.get(:blockchain, :blocks)
      assert length(blockchain) == 1
      assert blockchain |> List.first |> Map.fetch!(:id) == 234
    end

    test "do nothing when peer blockchain and own are equal", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000"])
      ConCache.put(:blockchain, :blocks, [%{id: 234, from: nil, to: "4001", amount: 100}])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["4001"], "blockchain" => [%{id: 234, from: nil, to: "4001", amount: 100}]}
      blockchain = ConCache.get(:blockchain, :blocks)
      assert length(blockchain) == 1
      assert blockchain |> List.first |> Map.fetch!(:id) == 234
    end
  end

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

    test "unable to transfer if blocks are yet unmined", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000","4001"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "4000", amount: 100, own_hash: nil}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "4001"}
      assert json_response(conn, 422) |> String.starts_with?("Previous block hasnt been mined yet")
    end

    test "able to transfer succesfully between users", %{conn: conn} do
      ConCache.put(:blockchain, :ports, ["4000","4001"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "4000", amount: 100, own_hash: "ABCD"}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "4001"}
      assert json_response(conn, 200) |> String.starts_with?("Block added successfully")
      assert length(ConCache.get(:blockchain, :blocks)) == 2
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
