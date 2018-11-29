defmodule Blexchain.UsersControllerTest do
  use Blexchain.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "gossip" do
    test "update own peers given peer node", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4"])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["1.2.3.5"], "blockchain" => nil}
      assert ConCache.get(:blockchain, :peers) |> Enum.member?("1.2.3.5")
    end

    test "keep own blockchain when peer blockchain is nil", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4"])
      ConCache.put(:blockchain, :blocks, [%{id: 123, from: nil, to: "1.2.3.4", amount: 100}])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["1.2.3.5"], "blockchain" => nil}
      blockchain = ConCache.get(:blockchain, :blocks)
      assert length(blockchain) == 1
      assert blockchain |> List.first |> Map.fetch!(:id) == 123
    end

    test "keep peer blockchain when own is nil", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4"])
      ConCache.put(:blockchain, :blocks, nil)
      post conn, gossip_path(conn, :gossip), %{"peers" => ["1.2.3.5"], "blockchain" => [%{id: 234, from: nil, to: "1.2.3.5", amount: 100}]}
      blockchain = ConCache.get(:blockchain, :blocks)
      assert length(blockchain) == 1
      assert blockchain |> List.first |> Map.fetch!(:id) == 234
    end

    test "do nothing when peer blockchain and own are equal", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4"])
      ConCache.put(:blockchain, :blocks, [%{id: 234, from: nil, to: "1.2.3.5", amount: 100}])
      post conn, gossip_path(conn, :gossip), %{"peers" => ["1.2.3.5"], "blockchain" => [%{id: 234, from: nil, to: "1.2.3.5", amount: 100}]}
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
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "9.8.7.6", "to" => nil}
      assert json_response(conn, 400) |> String.starts_with?("9.8.7.6 doesnt exist")
    end

    test "unable to transfer when to user does not exist", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4"])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "1.2.3.4", "to" => "9.8.7.6"}
      assert json_response(conn, 400) |> String.starts_with?("9.8.7.6 doesnt exist")
    end

    test "unable to transfer if blocks are yet unmined", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4","1.2.3.5"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "1.2.3.4", amount: 100, own_hash: nil}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "1.2.3.4", "to" => "1.2.3.5"}
      assert json_response(conn, 422) |> String.starts_with?("Previous block hasnt been mined yet")
    end

    test "able to transfer succesfully between users", %{conn: conn} do
      ConCache.put(:blockchain, :peers, ["1.2.3.4","1.2.3.5"])
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "1.2.3.4", amount: 100, own_hash: "ABCD"}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "1.2.3.4", "to" => "1.2.3.5"}
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
