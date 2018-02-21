defmodule Blexchain.RSA do
  @private_file_name "key.pem"
  @public_file_name "key.pub"

  def generate_key_pair do
    {:ok, file} = File.open @private_file_name, [:write]
    {raw, 0} = System.cmd("openssl", ["genrsa","2048"], [stderr_to_stdout: true])
    raw |> :binary.match("-----BEGIN RSA")
      |> case do
        {i, _len} -> String.slice(raw, i..-1) |> (&IO.binwrite(file, &1)).()
        :nomatch -> IO.puts "Unable to generate private key!"
      end
    File.close file

    "openssl rsa -in #{@private_file_name} -pubout > #{@public_file_name}" |> String.to_charlist |> :os.cmd

    private_key = File.read! @private_file_name 
    public_key = File.read! @public_file_name

    File.rm @private_file_name 
    File.rm @public_file_name 
    
    {private_key, public_key}
  end

  def sign(msg, raw_private_key) do
    key = raw_private_key |> key_from_raw
    msg |> :public_key.encrypt_private(key) |> :base64.encode_to_string
  end

  def valid_signature?(msg, cypher, raw_public_key), do: msg == decrypt(cypher, raw_public_key)

  defp decrypt(cypher, raw_public_key) do
    key = raw_public_key |> key_from_raw
    cypher |> :base64.decode |> :public_key.decrypt_public(key)
  end

  defp key_from_raw(key), do: key |> :public_key.pem_decode |> List.first |> :public_key.pem_entry_decode
end
