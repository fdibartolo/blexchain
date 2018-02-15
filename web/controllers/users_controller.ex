defmodule Blexchain.UsersController do
  use Blexchain.Web, :controller

  def create(conn, %{"user" => u}) do
    user = u |> String.downcase
    # TODO: check if user exists first
    case ConCache.put(:balances, user, 0) do
      :ok -> print_state(); json conn, "User #{user} created OK!"
      _ -> json conn, "Something went wrong!"
    end
  end

  def transfer(conn, %{"from" => from, "to" => to, "amount" => amount}) do
    cond do
      amount <= 0 -> json (conn |> put_status(400)), "Cannot transfer this amount; it must be greater than 0"
      ConCache.get(:balances, from) == nil -> json (conn |> put_status(400)), "#{from} doesnt exist"
      ConCache.get(:balances, to) == nil -> json (conn |> put_status(400)), "#{to} doesnt exist"
      ConCache.get(:balances, from) < amount -> json (conn |> put_status(400)), "#{from} has insuficient funds to make the transfer"
      true -> do_transfer(from, to, amount); json conn, "Transfered #{amount} from #{from} to #{to} OK!"
    end
  end

  defp do_transfer(from, to, amount) do
    ConCache.get(:balances, from)
    |> (&ConCache.put(:balances, from, (&1 - amount))).()

    ConCache.get(:balances, to)
    |> (&ConCache.put(:balances, to, (&1 + amount))).()

    print_state()
  end

  defp print_state do
    ConCache.ets(:balances)
    |> :ets.tab2list
    |> Enum.map(fn {u,b} -> IO.puts "User #{u} has a balance of #{b}" end)
  end
end
