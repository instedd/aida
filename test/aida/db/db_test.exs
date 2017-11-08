defmodule Aida.DBTest do
  use Aida.DataCase

  alias Aida.DB

  describe "bots" do
    alias Aida.DB.Bot

    @manifest "some manifest"
    @updated_manifest "some updated manifest"

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

    test "create_bot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DB.create_bot(@invalid_attrs)
    end

    test "update_bot/2 with valid data updates the bot" do
      bot = bot_fixture()
      assert {:ok, bot} = DB.update_bot(bot, @update_attrs)
      assert %Bot{} = bot
      assert bot.manifest == @updated_manifest
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

    test "change_bot/1 returns a bot changeset" do
      bot = bot_fixture()
      assert %Ecto.Changeset{} = DB.change_bot(bot)
    end
  end
end
