defmodule Blexchain.Router do
  use Blexchain.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Blexchain do
    pipe_through :api
  end
end
