defmodule Blexchain.AboutController do
  use Blexchain.Web, :controller

  # alias Blexchain.About

  def index(conn, _params) do
    json conn, "Hi! This is a simple blockchain implementation, 100% written in Elixir."
  end
end
