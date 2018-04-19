defmodule Aida.DB.SessionTest do
  use Aida.DataCase
  use Aida.SessionHelper
  alias Aida.Repo
  alias Aida.DB.{Session, MessageLog, Image}

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

  describe "on delete" do
    test "deletes message logs of that session" do
      bot_id = Ecto.UUID.generate
      id1 = Ecto.UUID.generate
      id2 = Ecto.UUID.generate
      new_session({id1, %{}}) |> Session.save
      new_session({id2, %{}}) |> Session.save
      MessageLog.create(%{bot_id: bot_id, session_id: id1, direction: "incoming", content_type: "text", content: "Hello"})
      MessageLog.create(%{bot_id: bot_id, session_id: id2, direction: "incoming", content_type: "text", content: "Hello"})

      Session.delete(id1)

      assert MessageLog |> Repo.all |> Enum.count == 1
    end

    test "deletes images of that session" do
      bot_id = Ecto.UUID.generate
      id1 = Ecto.UUID.generate
      id2 = Ecto.UUID.generate
      new_session({id1, %{}}) |> Session.save
      new_session({id2, %{}}) |> Session.save
      %Image{} |> Image.changeset(%{binary: <<0,1>>, binary_type: "image/jpeg", source_url: "foo", bot_id: bot_id, session_id: id1}) |> Repo.insert
      %Image{} |> Image.changeset(%{binary: <<0,1>>, binary_type: "image/jpeg", source_url: "foo", bot_id: bot_id, session_id: id2}) |> Repo.insert

      Session.delete(id1)

      assert Image |> Repo.all |> Enum.count == 1
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
