defmodule Blexchain.FakeClient do
  def gossip_with_peer(_,_,_), do: :ok

  def public_key_of(port), do: "-----BEGIN FAKE PUBLIC KEY-----#{port}-----END PUBLIC KEY-----"

  def transfer(%{to: "invalid"}), do: {400, "invalid doesnt exist"}
  def transfer(_), do: {200, "Block added successfully"}
end
