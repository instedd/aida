defmodule Aida.SessionTest do
  use Aida.DataCase
  alias Aida.{Session, SessionStore}

  test "create new session" do
    session = Session.new("session_id")
    assert session == %Session{
      id: "session_id",
      is_new?: true,
      values: %{}
    }
  end

  test "create existing session" do
    session = Session.new("session_id", %{"foo" => "bar"})
    assert session == %Session{
      id: "session_id",
      is_new?: false,
      values: %{"foo" => "bar"}
    }
  end

  describe "with session store" do
    setup do
      SessionStore.start_link
      :ok
    end

    test "return new session when it doesn't exist" do
      assert Session.load("session_id") == %Session{
        id: "session_id",
        is_new?: true,
        values: %{}
      }
    end

    test "load session from store" do
      SessionStore.save("session_id", %{"foo" => "bar"})

      assert Session.load("session_id") == %Session{
        id: "session_id",
        is_new?: false,
        values: %{"foo" => "bar"}
      }
    end

    test "save session to store" do
      session = Session.new("session_id", %{"foo" => "bar"})
      assert Session.save(session) == :ok

      assert SessionStore.find("session_id") == %{"foo" => "bar"}
    end
  end
end
