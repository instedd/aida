defmodule Aida.CryptoTest do
  alias Aida.Crypto
  use ExUnit.Case

  @server_sk "ixSMuoBEXwQzSiIY2txyKq/y9nOhgl0sYaBBrbijock=" |> Base.decode64!()
  @server_pk "vxCow3fktGmnjNxBOirDBFc1lvPAlF5I5mjW9CQEfiI=" |> Base.decode64!()
  @server_pair {@server_sk, @server_pk}

  @user1_sk "fYMuW3R5S8F17wkaQ3oplg+VE9CYJatp9b40gnfXEW4=" |> Base.decode64!()
  @user1_pk "PXV+4U9XcgZcnr51Pb2gc1/cI9hApezG2cdAV2/sqEA=" |> Base.decode64!()

  @user2_sk "sSS9MqLF/XzaOhEF5bvwKugQ/53D2j3HkhiqcrG2qe8=" |> Base.decode64!()
  @user2_pk "7TeiQ4HvQUtBIIoMK6korzroufiUMvX4z9bCV3v+OTQ=" |> Base.decode64!()

  @nonce_base "12345678901234567890"

  test "Verify test keys" do
    assert @server_pk == @server_sk |> Kcl.derive_public_key()
    assert @user1_pk == @user1_sk |> Kcl.derive_public_key()
    assert @user2_pk == @user2_sk |> Kcl.derive_public_key()
  end

  describe "Crypto box" do
    test "Create box with encrypted values" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk], @nonce_base)

      expected_box = %Crypto.Box{
        public_key: @server_pk,
        nonce_base: @nonce_base,
        recipients: [
          %{
            public_key: @user1_pk,
            encrypted: Kcl.box("Hello", @nonce_base <> "0000", @server_sk, @user1_pk) |> elem(0)
          },
          %{
            public_key: @user2_pk,
            encrypted: Kcl.box("Hello", @nonce_base <> "0001", @server_sk, @user2_pk) |> elem(0)
          }
        ]
      }

      assert expected_box == box
    end

    test "Decrypt from box" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk], @nonce_base)

      assert "Hello" == box |> Crypto.Box.decrypt(@user1_sk, @user1_pk)
      assert "Hello" == box |> Crypto.Box.decrypt(@user1_sk)
      assert "Hello" == box |> Crypto.Box.decrypt(@user2_sk, @user2_pk)
      assert "Hello" == box |> Crypto.Box.decrypt(@user2_sk)
    end

    test "Generate random nonce" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk])
      recipient = box.recipients |> hd()
      data = Kcl.unbox(recipient.encrypted, box.nonce_base <> "0000", @user1_sk, @server_pk) |> elem(0)

      assert "Hello" == data

      second_box = Crypto.Box.build("Hello", @server_pair, [@user1_pk])
      refute second_box.nonce_base == box.nonce_base
    end

    test "Encode box" do
      encoded_box =
        Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk], @nonce_base)
        |> Crypto.Box.encode()

      expected_encoded_box =
        [
          @server_pk,
          @nonce_base,
          [
            [@user1_pk, Kcl.box("Hello", @nonce_base <> "0000", @server_sk, @user1_pk) |> elem(0)],
            [@user2_pk, Kcl.box("Hello", @nonce_base <> "0001", @server_sk, @user2_pk) |> elem(0)]
          ]
        ]
        |> Msgpax.pack!(iodata: false)
        |> Base.encode64()

      assert expected_encoded_box == encoded_box
    end

    test "Decode box" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk])
      encoded_box = Crypto.Box.encode(box)

      assert box == Crypto.Box.decode(encoded_box)
    end

    test "Convert box to JSON" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk], @nonce_base)
      encoded_box = box |> Crypto.Box.encode()

      expected_json = %{
        "type" => "encrypted",
        "version" => "1",
        "data" => encoded_box
      }

      assert expected_json == box |> Crypto.Box.to_json()
    end

    test "Create box from JSON" do
      box = Crypto.Box.build("Hello", @server_pair, [@user1_pk, @user2_pk])
      json = Crypto.Box.to_json(box)

      assert box == Crypto.Box.from_json(json)
    end
  end

  describe "Crypto helpers" do
    test "Create box" do
      box = Crypto.box("Hello", [@user1_pk])
      assert %Crypto.Box{
        public_key: server_pk,
        nonce_base: nonce_base,
        recipients: [%{
          public_key: @user1_pk,
          encrypted: data
        }]
      } = box

      assert "Hello" == Kcl.unbox(data, nonce_base <> "0000", @user1_sk, server_pk) |> elem(0)
    end

    test "Encrypt to json" do
      json = Crypto.encrypt("Hello", [@user1_pk])
      assert %{
        "type" => "encrypted",
        "version" => "1",
        "data" => data
      } = json
      assert {:ok, _} = Base.decode64(data)
    end

    test "Decrypt from json" do
      json = Crypto.encrypt("Hello", [@user1_pk, @user2_pk])
      assert "Hello" == Crypto.decrypt(json, @user1_sk, @user1_pk)
      assert "Hello" == Crypto.decrypt(json, @user1_sk)
    end

    test "Encrypt with server keypair" do
      nonce = :crypto.strong_rand_bytes(24)
      private = Application.get_env(:aida, Aida.Crypto)[:private_key]
      public = Kcl.derive_public_key(private)

      encrypted = Crypto.server_encrypt("Hello", nonce)

      assert "Hello" == Kcl.secretunbox(encrypted, nonce, Kcl.shared_secret(private, public))
    end

    test "Decrypt with server keypair" do
      nonce = :crypto.strong_rand_bytes(24)
      private = Application.get_env(:aida, Aida.Crypto)[:private_key]
      public = Kcl.derive_public_key(private)

      encrypted = Kcl.secretbox("Hello", nonce, Kcl.shared_secret(private, public))

      assert "Hello" == Crypto.server_decrypt(encrypted, nonce)
    end
  end
end
