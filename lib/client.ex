defmodule Blexchain.Client do
  @url "http://localhost"
  @headers ["Content-Type": "application/json"]

  def gossip_nodes(port, peer_ports) do
    p = peer_ports |> Poison.encode |> elem(1)
    HTTPotion.post "#{@url}:#{port}/gossip", [body: "{\"peers\": #{p}}", headers: @headers]
  end
end
