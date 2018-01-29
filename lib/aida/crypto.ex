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

  @spec decrypt(map, Kcl.key(), nil | Kcl.key()) :: binary
  def decrypt(json, recipient_sk, recipient_pk \\ nil) do
    json
    |> Box.from_json()
    |> Box.decrypt(recipient_sk, recipient_pk)
  end

  @spec server_encrypt(binary, Kcl.nonce()) :: binary
  def server_encrypt(data, nonce) do
    {private, public} = obtain_server_keypair()
    shared_secret = Kcl.shared_secret(private, public)
    Kcl.secretbox(data, nonce, shared_secret)
  end

  @spec server_decrypt(binary, Kcl.nonce()) :: binary
  def server_decrypt(data, nonce) do
    {private, public} = obtain_server_keypair()
    shared_secret = Kcl.shared_secret(private, public)
    Kcl.secretunbox(data, nonce, shared_secret)
  end

  @spec obtain_server_keypair() :: {Kcl.key(), Kcl.key()}
  defp obtain_server_keypair() do
    private = Application.get_env(:aida, __MODULE__)[:private_key]
    public = Kcl.derive_public_key(private)
    {private, public}
  end
end
