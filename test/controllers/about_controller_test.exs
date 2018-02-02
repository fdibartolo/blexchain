defmodule Blexchain.AboutControllerTest do
  use Blexchain.ConnCase

  # alias Blexchain.About

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "displays about info", %{conn: conn} do
    conn = get conn, about_path(conn, :index)
    assert json_response(conn, 200) |> String.starts_with?("Hi!")
  end
end
