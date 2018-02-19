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
      ConCache.put(:blockchain, :blocks, [%{from: nil, to: "4000", amount: 100}])
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "4000", "to" => "4001"}
      assert json_response(conn, 200) |> String.starts_with?("Transaction block added, to be mined soon to assert validity")
      assert length(ConCache.get(:blockchain, :blocks)) == 2
    end
  end
end
