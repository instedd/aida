defmodule Aida.Crypto do
  alias Aida.Crypto.Box

  @spec box(binary, list(Kcl.key())) :: Box.t
  def box(data, recipient_pks) do
    server_pair = Kcl.generate_key_pair()
    Box.build(data, server_pair, recipient_pks)
  end

  @spec encrypt(binary, list(Kcl.key())) :: map
  def encrypt(data, recipient_pks) do
    box(data, recipient_pks)
    |> Box.to_json()
  end
end
