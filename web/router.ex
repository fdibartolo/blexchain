defmodule Blexchain.Router do
  use Blexchain.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Blexchain do
    pipe_through :api

    resources "/about", AboutController, only: [:index]
  end
end
