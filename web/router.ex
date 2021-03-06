defmodule Blexchain.Router do
  use Blexchain.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Blexchain do
    pipe_through :api

    resources "/about", AboutController, only: [:index]
    post "/gossip", UsersController, :gossip, as: :gossip
    post "/transfer", UsersController, :transfer, as: :transfer
    get "/public_key", UsersController, :public_key, as: :public_key
  end
end
