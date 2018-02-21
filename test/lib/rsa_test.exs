defmodule Blexchain.RSATest do
  use ExUnit.Case

  @keys Blexchain.RSA.generate_key_pair

  test "generate private and public keys" do
    {private_key, public_key} = @keys
    assert private_key |> String.starts_with?("-----BEGIN RSA PRIVATE KEY-----")
    assert public_key |> String.starts_with?("-----BEGIN PUBLIC KEY-----")
  end

  test "sign and validate signature of a message" do
    {private_key, public_key} = @keys
    cyphertext = Blexchain.RSA.sign "some message", private_key
    assert Blexchain.RSA.valid_signature?("some message", cyphertext, public_key)
  end
end
