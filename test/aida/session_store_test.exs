defmodule Aida.SessionStoreTest do
  use Aida.DataCase
  alias Aida.{SessionStore, DB, Repo}
  alias Aida.DB.{MessageLog, Image}

  @uuid "eb566b7d-e88f-40cc-9ee5-70f7bdec8e45"

  setup do
    SessionStore.start_link
    :ok
  end

  test "find non existing session returns :not_found" do
    assert SessionStore.find("foo") == :not_found
  end

  test "save and find session" do
    data = %{"foo" => 1, "bar" => 2}
    assert SessionStore.save("session_id", @uuid, data) == :ok
    assert SessionStore.find("session_id") == {"session_id", @uuid, data}
  end

  test "loads data from DB when the session is not loaded in memory" do
    data = %{"foo" => 1, "bar" => 2}
    assert {:ok, _session} = DB.save_session("session_id", @uuid, data)
    assert SessionStore.find("session_id") == {"session_id", @uuid, data}
  end

  test "data loaded from DB is cached in memory" do
    data = %{"foo" => 1, "bar" => 2}
    assert {:ok, _session} = DB.save_session("session_id", @uuid, data)
    assert SessionStore.find("session_id") == {"session_id", @uuid, data}

    # Delete all sessions from DB. Our data should be still in memory
    Aida.DB.Session |> Aida.Repo.delete_all

    assert SessionStore.find("session_id") == {"session_id", @uuid, data}
  end

  test "saved session data is persisted in DB" do
    data = %{"foo" => 1, "bar" => 2}
    assert SessionStore.save("session_id", @uuid, data) == :ok
    assert session = Aida.DB.get_session("session_id")
    assert session.data == data
  end

  test "delete session" do
    data = %{"foo" => 1, "bar" => 2}
    assert SessionStore.save("session_id", @uuid, data) == :ok
    assert SessionStore.delete("session_id") == :ok
    assert SessionStore.find("session_id") == :not_found
  end

  test "delete message logs of that session when deleting session" do
    data = %{"foo" => 1, "bar" => 2}
    other_uuid = Ecto.UUID.generate
    SessionStore.save("session_id", @uuid, data)
    SessionStore.save("other_session_id", other_uuid, data)
    MessageLog.create(%{bot_id: Ecto.UUID.generate, session_id: "session_id", session_uuid: @uuid, direction: "incoming", content_type: "text", content: "Hello"})
    MessageLog.create(%{bot_id: Ecto.UUID.generate, session_id: "other_session_id", session_uuid: other_uuid, direction: "incoming", content_type: "text", content: "Hello"})

    SessionStore.delete("session_id")
    assert MessageLog |> Repo.all |> Enum.count == 1
  end

  test "delete images of that session when deleting session" do
    data = %{"foo" => 1, "bar" => 2}
    SessionStore.save("session_id", @uuid, data)
    SessionStore.save("other_session_id", Ecto.UUID.generate, data)
    bot_id = Ecto.UUID.generate

    %Image{} |> Image.changeset(%{binary: <<0,1>>, binary_type: "image/jpeg", source_url: "foo", bot_id: bot_id, session_id: "session_id"})
      |> Repo.insert
    %Image{} |> Image.changeset(%{binary: <<0,1>>, binary_type: "image/jpeg", source_url: "foo", bot_id: bot_id, session_id: "other_session_id"})
      |> Repo.insert

    SessionStore.delete("session_id")
    assert Image |> Repo.all |> Enum.count == 1
  end
end
