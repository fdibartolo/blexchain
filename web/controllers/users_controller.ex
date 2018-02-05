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

  defp print_state do
    ConCache.ets(:balances)
    |> :ets.tab2list
    |> Enum.map(fn {u,b} -> IO.puts "User #{u} has a balance of #{b}" end)
  end
end
