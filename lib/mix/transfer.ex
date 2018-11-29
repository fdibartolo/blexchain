defmodule Mix.Tasks.Blexchain.Transfer do
  use Mix.Task
  import IO.ANSI
  @http_client Application.get_env(:blexchain, :http_client)

  @shortdoc "Post a transfer transaction to the blexchain"
  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:httpotion)

    IO.puts "#{yellow()}About to transfer to blexchain..."
    body = parse(args, %{})

    case body |> Map.keys |> Enum.sort == [:amount, :from, :to] do
      true -> request(body)
      false -> IO.puts "All three args must be provided; i.e 'docker exec <CONTAINER> mix blexchain.transfer from:1.2.3.4 to:2.3.4.5 amount:100'"
    end
  end

  defp request(body) do
    case @http_client.transfer(body) do
      {200, message} -> IO.puts "#{green()}#{message}#{reset()}"
      {_, message} -> IO.puts "#{red()}#{message}#{reset()}"
    end
  end

  defp parse([], acc), do: acc
  defp parse([arg|args], acc) do
    parse(arg) |> case do
      {:ignore, _} -> parse(args, acc)
      {k,v} -> parse(args, Map.put(acc, k, v))
    end
  end

  defp parse("from:" <> from), do: {:from, from}
  defp parse("to:" <> to), do: {:to, to}
  defp parse("amount:" <> amount), do: {:amount, amount |> String.to_integer}
  defp parse(_), do: {:ignore, nil}
end
