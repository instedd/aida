defmodule Aida.SessionTest do
  use Aida.DataCase
  alias Aida.{DB, DB.Session}

  @provider "facebook"
  @provider_key "1234/5678"

  setup do
    {:ok, bot} = DB.create_bot(%{manifest: %{}})
    [bot_id: bot.id]
  end

  test "create new session", %{bot_id: bot_id} do
    session = Session.new({bot_id, @provider, @provider_key})
    assert %Session{
      bot_id: ^bot_id,
      provider: @provider,
      provider_key: @provider_key,
      is_new: true,
      data: %{}
    } = session
  end

  test "save existing session", %{bot_id: bot_id} do
    session = Session.new({bot_id, @provider, @provider_key})
    session_id = session.id
    session = session |> Session.merge(%{"foo" => "bar"}) |> Session.save
    assert %Session{
      id: ^session_id,
      bot_id: ^bot_id,
      provider: @provider,
      provider_key: @provider_key,
      data: %{"foo" => "bar"}
    } = session
  end

  describe "persisted in database" do
    test "return new session when it doesn't exist", %{bot_id: bot_id} do
      loaded_session = Session.find_or_create(bot_id, @provider, @provider_key)
      assert %Session{
        bot_id: ^bot_id,
        provider: @provider,
        provider_key: @provider_key,
        is_new: true,
        data: %{}
      } = loaded_session
    end

    test "load persisted session", %{bot_id: bot_id} do
      Session.new({bot_id, @provider, @provider_key})
        |> Session.merge(%{"foo" => "bar"})
        |> Session.save

      loaded_session = Session.find_or_create(bot_id, @provider, @provider_key)
      assert %Session{
        bot_id: ^bot_id,
        provider: @provider,
        provider_key: @provider_key,
        is_new: true,
        data: %{"foo" => "bar"}
      } = loaded_session
    end

  end

  describe "value store" do
    test "get", %{bot_id: bot_id} do
      session = Session.new({bot_id, @provider, @provider_key}) |> Session.merge(%{"foo" => "bar"})
      assert session |> Session.get_value("foo") == "bar"
    end

    test "put", %{bot_id: bot_id} do
      session = Session.new({bot_id, @provider, @provider_key}) |> Session.put("foo", "bar")
      assert session.data == %{"foo" => "bar"}
    end

    test "put nil deletes key", %{bot_id: bot_id} do
      session = Session.new({bot_id, @provider, @provider_key}) |> Session.put("foo", "bar")
      session = session |> Session.put("foo", nil)

      assert session.data == %{}
    end
  end
end
