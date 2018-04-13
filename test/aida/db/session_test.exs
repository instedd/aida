defmodule Aida.DB.SessionTest do
  use Aida.DataCase
  alias Aida.DB.Session
  alias Aida.Repo

  @session_id Ecto.UUID.generate
  @bot_id Ecto.UUID.generate
  @provider "facebook"
  @provider_key "1234/5678"

  test "can insert and retrieve sessions" do
    data = %{"foo" => 1, "bar" => 2}

    %Session{}
      |> Session.changeset(%{id: @session_id, bot_id: @bot_id, provider: @provider, provider_key: @provider_key, data: data})
      |> Repo.insert!

    [session] = Session |> Repo.all
    assert session.id == @session_id
    assert session.data == data
    assert session.provider == @provider
    assert session.provider_key == @provider_key
    assert session.bot_id == @bot_id
  end

  test "cannot insert two sessions with same id" do
    %Session{}
      |> Session.changeset(%{id: @session_id, bot_id: @bot_id, provider: @provider, provider_key: @provider_key})
      |> Repo.insert!

    assert_raise Ecto.ConstraintError, fn ->
      %Session{}
        |> Session.changeset(%{id: @session_id, bot_id: @bot_id, provider: "ws", provider_key: @provider_key})
        |> Repo.insert!
    end
  end

  # TODO: This should work
  # test "cannot insert two sessions with same uuid" do
  #   %Session{}
  #     |> Session.changeset(%{id: "session_id", uuid: @uuid, data: %{}})
  #     |> Repo.insert!

  #   assert_raise Ecto.ConstraintError, fn ->
  #     %Session{}
  #       |> Session.changeset(%{id: "session_id_2", uuid: @uuid, data: %{}})
  #       |> Repo.insert!
  #   end
  # end
end
