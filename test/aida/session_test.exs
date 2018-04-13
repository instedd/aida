defmodule Aida.SessionTest do
  use Aida.DataCase
  alias Aida.DB.Session

  @id "cecaeffa-1fc4-49f1-925a-a5d17047504f"
  @session_struct %{
    bot_id: Ecto.UUID.generate,
    provider: "facebook",
    provider_key: "1234/5678"
  }

  test "create new session" do
    session = Session.new(@id)
    assert session == %Session{
      id: @id,
      is_new?: true,
      data: %{}
    }
  end

  test "create existing session" do
    session = Session.new({@id, %{"foo" => "bar"}})
    assert session == %Session{
      id: @id,
      is_new?: false,
      data: %{"foo" => "bar"}
    }
  end

  describe "persisted in database" do
    test "return new session when it doesn't exist" do
      loaded_session = Session.load(@session_struct)
      assert loaded_session == %Session{
        id: loaded_session.id,
        bot_id: @session_struct.bot_id,
        provider: @session_struct.provider,
        provider_key: @session_struct.provider_key,
        is_new?: true,
        data: %{}
      }
    end

    test "load persisted session" do
      Session.new(@session_struct)
        |> Session.merge(%{"foo" => "bar"})
        |> Session.save

      loaded_session = Session.load(@session_struct)
      assert loaded_session.bot_id == @session_struct.bot_id
      assert loaded_session.provider == @session_struct.provider
      assert loaded_session.provider_key == @session_struct.provider_key
      assert !loaded_session.is_new?
      assert loaded_session.data == %{"foo" => "bar"}
    end

    # test "save session to store" do
    #   session = Session.new({"session_id", @uuid, %{"foo" => "bar"}})
    #   assert Session.save(session) == :ok

    #   assert SessionStore.find("session_id") == {"session_id", @uuid, %{"foo" => "bar"}}
    # end
  end

  describe "value store" do
    test "get" do
      session = Session.new(@session_struct) |> Session.merge(%{"foo" => "bar"})
      assert session |> Session.get("foo") == "bar"
    end

    test "put" do
      session = Session.new(@session_struct) |> Session.put("foo", "bar")
      assert session.data == %{"foo" => "bar"}
    end

    test "put nil deletes key" do
      session = Session.new(@session_struct) |> Session.put("foo", "bar")
      session = session |> Session.put("foo", nil)

      assert session.data == %{}
    end
  end
end
