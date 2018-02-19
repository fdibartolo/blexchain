defmodule Blexchain.Client do
  @url "http://localhost"
  @headers ["Content-Type": "application/json"]

  def gossip_with_peer(port, peer_ports, blockchain) do
    p = peer_ports |> Poison.encode!
    b = blockchain |> Poison.encode!
    HTTPotion.post "#{@url}:#{port}/gossip", [body: "{\"peers\": #{p}, \"blockchain\": #{b}}", headers: @headers]
  end
end
