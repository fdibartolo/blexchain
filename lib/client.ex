defmodule Blexchain.Client do
  @url "http://localhost"
  @headers ["Content-Type": "application/json"]

  def gossip_with_peer(port, peer_ports, blockchain) do
    body = %{peers: peer_ports, blockchain: blockchain} |> Poison.encode!
    HTTPotion.post "#{@url}:#{port}/gossip", [body: body, headers: @headers]
  end

  def public_key_of(peer_port) do
    response = HTTPotion.get "#{@url}:#{peer_port}/public_key", [headers: @headers]
    response.body |> Poison.decode!
  end
end
