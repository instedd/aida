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
        nonce = nonce_base <> (index |> Integer.to_string() |> String.pad_leading(4, "0"))
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
      box.public_key,
      box.nonce_base,
      box.recipients
      |> Enum.map(fn recipient ->
        [
          recipient.public_key,
          recipient.encrypted
        ]
      end)
    ]
    |> Msgpax.pack!(iodata: false)
    |> Base.encode64()
  end

  @spec to_json(t) :: map
  def to_json(box) do
    %{
      "type" => "encrypted",
      "version" => "1",
      "data" => encode(box)
    }
  end
end
