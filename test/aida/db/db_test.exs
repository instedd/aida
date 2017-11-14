defmodule Aida.DBTest do
  use Aida.DataCase

  alias Aida.{DB, BotManager, ChannelRegistry}

  describe "bots" do
    alias Aida.DB.Bot

    @manifest File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    @updated_manifest %{skills: [], variables: [], channels: []}

    @valid_attrs %{manifest: @manifest}
    @update_attrs %{manifest: @updated_manifest}
    @invalid_attrs %{manifest: nil}

    def bot_fixture(attrs \\ %{}) do
      {:ok, bot} =
        attrs
        |> Enum.into(@valid_attrs)
        |> DB.create_bot()

      bot
    end

    test "list_bots/0 returns all bots" do
      bot = bot_fixture()
      assert DB.list_bots() == [bot]
    end

    test "get_bot!/1 returns the bot with given id" do
      bot = bot_fixture()
      assert DB.get_bot!(bot.id) == bot
    end

    test "create_bot/1 with valid data creates a bot" do
      assert {:ok, %Bot{} = bot} = DB.create_bot(@valid_attrs)
      assert bot.manifest == @manifest
    end

    test "create_bot/1 registers bot" do
      ChannelRegistry.start_link
      BotManager.start_link

      {:ok, bot} = DB.create_bot(@valid_attrs)
      BotManager.flush
      assert %Aida.Bot{} = BotManager.find(bot.id)
    end

    test "create_bot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DB.create_bot(@invalid_attrs)
    end

    test "update_bot/2 with valid data updates the bot" do
      bot = bot_fixture()
      assert {:ok, bot} = DB.update_bot(bot, @update_attrs)
      assert %Bot{} = bot
      assert bot.manifest == @updated_manifest
    end

    test "update_bot/2 notifies the manager about the change" do
      ChannelRegistry.start_link
      BotManager.start_link

      bot = bot_fixture()
      BotManager.flush()
      assert %Aida.Bot{channels: [_]} = BotManager.find(bot.id)

      assert {:ok, bot} = DB.update_bot(bot, @update_attrs)
      BotManager.flush()
      assert %Aida.Bot{channels: []} = BotManager.find(bot.id)
    end

    test "update_bot/2 with invalid data returns error changeset" do
      bot = bot_fixture()
      assert {:error, %Ecto.Changeset{}} = DB.update_bot(bot, @invalid_attrs)
      assert bot == DB.get_bot!(bot.id)
    end

    test "delete_bot/1 deletes the bot" do
      bot = bot_fixture()
      assert {:ok, %Bot{}} = DB.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> DB.get_bot!(bot.id) end
    end

    test "delete_bot/1 notifies the manager about the change" do
      ChannelRegistry.start_link
      BotManager.start_link

      bot = bot_fixture()
      BotManager.flush()
      assert %Aida.Bot{} = BotManager.find(bot.id)

      assert {:ok, %Bot{}} = DB.delete_bot(bot)
      BotManager.flush()
      assert BotManager.find(bot.id) == :not_found
    end

    test "change_bot/1 returns a bot changeset" do
      bot = bot_fixture()
      assert %Ecto.Changeset{} = DB.change_bot(bot)
    end

    test "save_session/2 stores session data" do
      data = %{"foo" => 1, "bar" => 2}
      {:ok, session} = DB.save_session("session_id", data)

      assert session.id == "session_id"
      assert session.data == data
    end

    test "get_session/1 returns nil if the session doesn't exist" do
      assert DB.get_session("session_id") == nil
    end

    test "get_session/1 returns the session with the given id" do
      data = %{"foo" => 1, "bar" => 2}
      {:ok, _session} = DB.save_session("session_id", data)

      session = DB.get_session("session_id")
      assert session.id == "session_id"
      assert session.data == data
    end

    test "save_session/2 replaces existing session" do
      {:ok, _session} = DB.save_session("session_id", %{"foo" => 1, "bar" => 2})
      {:ok, _session} = DB.save_session("session_id", %{"foo" => 3, "bar" => 4})

      session = DB.get_session("session_id")
      assert session.id == "session_id"
      assert session.data == %{"foo" => 3, "bar" => 4}
    end
  end
end
