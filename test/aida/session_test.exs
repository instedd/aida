defmodule Aida.SessionTest do
  use Aida.DataCase
  alias Aida.{Session, SessionStore}

  @uuid "cecaeffa-1fc4-49f1-925a-a5d17047504f"

  test "create new session" do
    session = Session.new("session_id", @uuid)
    assert session == %Session{
      id: "session_id",
      is_new?: true,
      uuid: @uuid,
      values: %{}
    }
  end

  test "create existing session" do
    session = Session.new({"session_id", @uuid, %{"foo" => "bar"}})
    assert session == %Session{
      id: "session_id",
      is_new?: false,
      uuid: @uuid,
      values: %{"foo" => "bar"}
    }
  end

  describe "with session store" do
    setup do
      SessionStore.start_link
      :ok
    end

    test "return new session when it doesn't exist" do
      loaded_session = Session.load("session_id")
      assert loaded_session == %Session{
        id: "session_id",
        is_new?: true,
        uuid: loaded_session.uuid,
        values: %{}
      }
    end

    test "load session from store" do
      SessionStore.save("session_id", @uuid, %{"foo" => "bar"})

      assert Session.load("session_id") == %Session{
        id: "session_id",
        is_new?: false,
        uuid: @uuid,
        values: %{"foo" => "bar"}
      }
    end

    test "save session to store" do
      session = Session.new({"session_id", @uuid, %{"foo" => "bar"}})
      assert Session.save(session) == :ok

      assert SessionStore.find("session_id") == {"session_id", @uuid, %{"foo" => "bar"}}
    end
  end

  describe "value store" do
    test "get" do
      session = Session.new({"session_id", @uuid, %{"foo" => "bar"}})

      assert session |> Session.get("foo") == "bar"
    end

    test "put" do
      session = Session.new({"session_id", @uuid, %{}})
      session = session |> Session.put("foo", "bar")

      assert session == %Session{
        id: "session_id",
        uuid: @uuid,
        is_new?: false,
        values: %{"foo" => "bar"}
      }
    end

    test "put nil deletes key" do
      session = Session.new({"session_id", @uuid, %{"foo" => "bar"}})
      session = session |> Session.put("foo", nil)

      assert session == %Session{
        id: "session_id",
        uuid: @uuid,
        is_new?: false,
        values: %{}
      }
    end
  end
end
