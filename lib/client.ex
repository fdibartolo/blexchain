defmodule Blexchain.Client do
  @headers ["Content-Type": "application/json"]

  def gossip_with_peer(peer, peers, blockchain) do
    body = %{peers: peers, blockchain: blockchain} |> Poison.encode!
    HTTPotion.post "http://#{peer}:#{System.get_env("PORT")}/gossip", [body: body, headers: @headers]
  end

  def public_key_of(peer) do
    response = HTTPotion.get "http://#{peer}:#{System.get_env("PORT")}/public_key", [headers: @headers]
    response.body |> Poison.decode!
  end

  def transfer(body) do
    response = HTTPotion.post "http://#{body.from}:#{System.get_env("PORT")}/transfer", 
      [body: body |> Poison.encode!, headers: @headers]

    {response.status_code, response.body |> Poison.decode!}
  end
end
