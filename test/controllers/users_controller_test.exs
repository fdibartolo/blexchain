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
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "invalid", "to" => nil}
      assert json_response(conn, 400) |> String.starts_with?("invalid doesnt exist")
    end

    test "unable to transfer when to user does not exist", %{conn: conn} do
      ConCache.put(:balances, "from", 1000)
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 10, "from" => "from", "to" => "invalid"}
      assert json_response(conn, 400) |> String.starts_with?("invalid doesnt exist")
    end

    test "unable to transfer when insufficient funds", %{conn: conn} do
      ConCache.put(:balances, "from", 10)
      ConCache.put(:balances, "to", 0)
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 20, "from" => "from", "to" => "to"}
      assert json_response(conn, 400) |> String.starts_with?("from has insuficient funds")
    end

    test "able to transfer succesfully between users", %{conn: conn} do
      ConCache.put(:balances, "from", 100)
      ConCache.put(:balances, "to", 0)
      conn = post conn, transfer_path(conn, :transfer), %{"amount" => 20, "from" => "from", "to" => "to"}
      assert json_response(conn, 200) |> String.starts_with?("Transfered 20 from from to to OK!")
    end

    test "able to decrease from user funds", %{conn: conn} do
      ConCache.put(:balances, "from", 100)
      ConCache.put(:balances, "to", 0)
      post conn, transfer_path(conn, :transfer), %{"amount" => 20, "from" => "from", "to" => "to"}
      assert ConCache.get(:balances, "from") == 80
    end

    test "able to increase to user funds", %{conn: conn} do
      ConCache.put(:balances, "from", 100)
      ConCache.put(:balances, "to", 0)
      post conn, transfer_path(conn, :transfer), %{"amount" => 20, "from" => "from", "to" => "to"}
      assert ConCache.get(:balances, "to") == 20
    end
  end
end
