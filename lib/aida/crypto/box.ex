defmodule Aida.Crypto.Box do
  @type nonce_base :: <<_::160>>
  @type recipient :: %{
          public_key: Kcl.key(),
          encrypted: binary
        }
  @type t :: %__MODULE__{
          public_key: Kcl.key(),
          nonce_base: nonce_base,
          recipients: list(recipient)
        }

  defstruct [:public_key, :nonce_base, :recipients]

  @spec build(binary, {Kcl.key(), Kcl.key()}, list(Kcl.key()), nonce_base) :: t
  def build(data, {server_sk, server_pk}, recipient_pks, nonce_base \\ generate_nonce()) do
    recipients =
      recipient_pks
      |> Enum.with_index()
      |> Enum.map(fn {pk, index} ->
        nonce = build_nonce(nonce_base, index)
        key = Kcl.shared_secret(server_sk, pk)

        %{
          public_key: pk,
          encrypted: Kcl.secretbox(data, nonce, key)
        }
      end)

    %__MODULE__{
      public_key: server_pk,
      nonce_base: nonce_base,
      recipients: recipients
    }
  end

  defp generate_nonce() do
    :crypto.strong_rand_bytes(20)
  end

  @spec encode(t) :: String.t()
  def encode(box) do
    [
      bin(box.public_key),
      bin(box.nonce_base),
      box.recipients
      |> Enum.map(fn recipient ->
        [
          bin(recipient.public_key),
          bin(recipient.encrypted)
        ]
      end)
    ]
    |> Msgpax.pack!(iodata: false)
    |> Base.encode64()
  end

  defp bin(data), do: Msgpax.Bin.new(data)

  @spec decode(String.t()) :: t
  def decode(encoded_box) do
    box_data =
      encoded_box
      |> Base.decode64!()
      |> Msgpax.unpack!()

    [public_key, nonce_base, recipients_data] = box_data

    recipients =
      recipients_data
      |> Enum.map(fn [recipient_pk, encrypted] ->
        %{public_key: recipient_pk, encrypted: encrypted}
      end)

    %__MODULE__{
      public_key: public_key,
      nonce_base: nonce_base,
      recipients: recipients
    }
  end

  @spec to_json(t) :: map
  def to_json(box) do
    %{
      "type" => "encrypted",
      "version" => "1",
      "data" => encode(box)
    }
  end

  @spec from_json(map) :: t
  def from_json(%{"type" => "encrypted", "version" => "1", "data" => encoded_box}) do
    decode(encoded_box)
  end

  @spec decrypt(t, Kcl.key(), nil | Kcl.key()) :: binary
  def decrypt(box, recipient_sk, recipient_pk \\ nil)

  def decrypt(box, recipient_sk, nil) do
    recipient_pk = Kcl.derive_public_key(recipient_sk)
    decrypt(box, recipient_sk, recipient_pk)
  end

  def decrypt(box, recipient_sk, recipient_pk) do
    {recipient, index} =
      box.recipients
      |> Enum.with_index()
      |> Enum.find(fn {recipient, _} ->
        recipient.public_key == recipient_pk
      end)

    nonce = build_nonce(box.nonce_base, index)
    key = Kcl.shared_secret(recipient_sk, box.public_key)
    Kcl.secretunbox(recipient.encrypted, nonce, key)
  end

  defp build_nonce(nonce_base, index) do
    nonce_base <> (index |> Integer.to_string() |> String.pad_leading(4, "0"))
  end
end
