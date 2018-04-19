defmodule Aida.SessionTest do
  use Aida.DataCase
  alias Aida.DB.Session

  @session_tuple {Ecto.UUID.generate, "facebook", "1234/5678"}

  test "create new session" do
    {bot_id, provider, provider_key} = @session_tuple
    session = Session.new(@session_tuple)
    assert %Session{
      bot_id: ^bot_id,
      provider: ^provider,
      provider_key: ^provider_key,
      is_new?: true,
      data: %{}
    } = session
  end

  test "save existing session" do
    {bot_id, provider, provider_key} = @session_tuple
    session = Session.new(@session_tuple)
    session_id = session.id
    session = session |> Session.merge(%{"foo" => "bar"}) |> Session.save
    assert %Session{
      id: ^session_id,
      bot_id: ^bot_id,
      provider: ^provider,
      provider_key: ^provider_key,
      data: %{"foo" => "bar"}
    } = session
  end

  describe "persisted in database" do
    test "return new session when it doesn't exist" do
      {bot_id, provider, provider_key} = @session_tuple
      loaded_session = Session.find_or_create(bot_id, provider, provider_key)
      assert %Session{
        bot_id: ^bot_id,
        provider: ^provider,
        provider_key: ^provider_key,
        is_new?: true,
        data: %{}
      } = loaded_session
    end

    test "load persisted session" do
      {bot_id, provider, provider_key} = @session_tuple
      Session.new(@session_tuple)
        |> Session.merge(%{"foo" => "bar"})
        |> Session.save

      loaded_session = Session.find_or_create(bot_id, provider, provider_key)
      assert %Session{
        bot_id: ^bot_id,
        provider: ^provider,
        provider_key: ^provider_key,
        is_new?: false,
        data: %{"foo" => "bar"}
      } = loaded_session
    end

  end

  describe "value store" do
    test "get" do
      session = Session.new(@session_tuple) |> Session.merge(%{"foo" => "bar"})
      assert session |> Session.get_value("foo") == "bar"
    end

    test "put" do
      session = Session.new(@session_tuple) |> Session.put("foo", "bar")
      assert session.data == %{"foo" => "bar"}
    end

    test "put nil deletes key" do
      session = Session.new(@session_tuple) |> Session.put("foo", "bar")
      session = session |> Session.put("foo", nil)

      assert session.data == %{}
    end
  end
end
