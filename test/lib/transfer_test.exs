defmodule Mix.Tasks.Blexchain.TransferTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  setup context do
    output = capture_io(fn -> Mix.Tasks.Blexchain.Transfer.run(context[:args]) end)
    {:ok, output: output}
  end

  @tag args: []
  test "no args should print proper message", %{output: output} do
    assert output |> String.contains?("All three args must be provided")
  end

  @tag args: ["from:12", "to:34", "another:val"]
  test "missing args should print proper message", %{output: output} do
    assert output |> String.contains?("All three args must be provided")
  end

  @tag args: ["from:12", "to:invalid", "amount:10"]
  test "peer port is not listening", %{output: output} do
    assert output |> String.contains?("invalid doesnt exist")
  end

  @tag args: ["from:12", "to:23", "amount:10"]
  test "transfer submitted successfully", %{output: output} do
    assert output |> String.contains?("Block added successfully")
  end

  @tag args: ["from:12", "to:23", "amount:10", "another:arg"]
  test "extra args are ignored", %{output: output} do
    assert output |> String.contains?("Block added successfully")
  end
end
