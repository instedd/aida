defmodule Aida.SessionTest do
  use ExUnit.Case
  alias Aida.Session

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
end
