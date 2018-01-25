defmodule Aida.SessionStoreTest do
  use Aida.DataCase
  alias Aida.{SessionStore, DB}

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
end
