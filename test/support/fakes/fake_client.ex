defmodule Blexchain.FakeClient do
  def gossip_with_peer(_,_,_), do: :ok

  def public_key_of(_), do: "-----BEGIN FAKE PUBLIC KEY-----\n-----END PUBLIC KEY-----"
end
