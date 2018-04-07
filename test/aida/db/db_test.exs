defmodule Aida.DBTest do
  use Aida.DataCase

  alias Aida.{DB, BotManager, ChannelRegistry}
  alias Aida.DB.{Session, SkillUsage}

  describe "bots" do
    alias Aida.DB.Bot

    @manifest File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    @updated_manifest %{skills: [], variables: [], channels: []}

    @valid_attrs %{manifest: @manifest}
    @update_attrs %{manifest: @updated_manifest}
    @invalid_attrs %{manifest: nil}
    @session_uuid_1 "27646aaa-d1bd-4fa3-836f-ef6479ccddb9"
    @session_uuid_2 "2b41f4d8-6749-442e-a39b-315f7ca91f5b"

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
      assert %Aida.Bot{channels: [_, _]} = BotManager.find(bot.id)

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
      assert {:ok, %{bot: %Bot{}}} = DB.delete_bot(bot)
      assert_raise Ecto.NoResultsError, fn -> DB.get_bot!(bot.id) end
    end

    test "delete_bot/1 notifies the manager about the change" do
      ChannelRegistry.start_link
      BotManager.start_link

      bot = bot_fixture()
      BotManager.flush()
      assert %Aida.Bot{} = BotManager.find(bot.id)

      assert {:ok, %{bot: %Bot{}}} = DB.delete_bot(bot)
      BotManager.flush()
      assert BotManager.find(bot.id) == :not_found
    end

    test "deletes associated sessions when deletes bot" do
      ChannelRegistry.start_link
      BotManager.start_link
      bot = bot_fixture()
      BotManager.flush()
      bot_session_id = "#{bot.id}/facebook/1234567890/1234"
      other_session_id = "other_session_id"

      DB.save_session(bot_session_id, Ecto.UUID.generate, %{})
      DB.save_session(other_session_id, Ecto.UUID.generate, %{})

      assert (Session |> Repo.all |> Enum.count == 2)

      DB.delete_bot(bot)
      BotManager.flush()

      assert (Session |> Repo.all |> Enum.count == 1)
    end

    test "deletes associated skill usages when deletes bot" do
      ChannelRegistry.start_link
      BotManager.start_link
      bot = bot_fixture()
      bot2 = bot_fixture()
      BotManager.flush()

      DB.create_or_update_skill_usage(%{bot_id: bot.id, user_id: "session_id", last_usage: Date.utc_today(), skill_id: "keyword_responder_1", user_generated: true})
      DB.create_or_update_skill_usage(%{bot_id: bot2.id, user_id: "other_session_id", last_usage: Date.utc_today(), skill_id: "keyword_responder_1", user_generated: true})

      assert (SkillUsage |> Repo.all |> Enum.count == 2)

      DB.delete_bot(bot)
      BotManager.flush()

      assert (SkillUsage |> Repo.all |> Enum.count == 1)
    end

    test "change_bot/1 returns a bot changeset" do
      bot = bot_fixture()
      assert %Ecto.Changeset{} = DB.change_bot(bot)
    end

    test "save_session/3 stores session data" do
      data = %{"foo" => 1, "bar" => 2}
      {:ok, session} = DB.save_session("session_id", @session_uuid_1, data)

      assert session.id == "session_id"
      assert session.uuid == @session_uuid_1
      assert session.data == data
    end

    test "get_session/1 returns nil if the session doesn't exist" do
      assert DB.get_session("session_id") == nil
    end

    test "get_session/1 returns the session with the given id" do
      data = %{"foo" => 1, "bar" => 2}
      {:ok, _session} = DB.save_session("session_id", @session_uuid_1, data)

      session = DB.get_session("session_id")
      assert session.id == "session_id"
      assert session.uuid == @session_uuid_1
      assert session.data == data
    end

    test "save_session/3 replaces existing session" do
      {:ok, _session} = DB.save_session("session_id", @session_uuid_1, %{"foo" => 1, "bar" => 2})
      {:ok, _session} = DB.save_session("session_id", @session_uuid_1, %{"foo" => 3, "bar" => 4})

      session = DB.get_session("session_id")
      assert session.id == "session_id"
      assert session.uuid == @session_uuid_1
      assert session.data == %{"foo" => 3, "bar" => 4}
    end

    test "get sessions by bot" do
      {:ok, s1} = DB.save_session("bot1/x", @session_uuid_1, %{})
      {:ok, _s2} = DB.save_session("bot2/x", @session_uuid_2, %{})

      sessions = DB.sessions_by_bot("bot1")
      assert sessions == [s1]
    end

    test "delete_session/1 deletes a session" do
      {:ok, _session} = DB.save_session("session_1", @session_uuid_1, %{"foo" => 1, "bar" => 2})
      {:ok, _session} = DB.save_session("session_2", @session_uuid_2, %{"foo" => 1, "bar" => 2})

      assert :ok = DB.delete_session("session_1")
      assert DB.get_session("session_1") == nil
      assert DB.get_session("session_2")
    end

    test "create_or_update_skill_usage/1 updates existing skill usage with the proper last_usage" do
      {:ok, bot} = DB.create_bot(%{manifest: %{}})
      bot_id = bot.id
      session_id = "facebook/123456789/987654321"
      session_id_2 = "facebook/0123456789/0987654321"
      skill_id = "language_detector"

      {:ok, skill_usage} = DB.create_or_update_skill_usage(%{bot_id: bot_id, user_id: session_id, last_usage: Date.add(Date.utc_today(), -2), skill_id: skill_id, user_generated: true})
      {:ok, _skill_usage} = DB.create_or_update_skill_usage(%{bot_id: bot_id, user_id: session_id_2, last_usage: Date.add(Date.utc_today(), -2), skill_id: skill_id, user_generated: true})
      {:ok, _skill_usage} = DB.create_or_update_skill_usage(%{bot_id: bot_id, user_id: session_id, last_usage: Date.utc_today(), skill_id: skill_id, user_generated: true})

      db_skill_usage = DB.get_skill_usage(skill_usage.id)
      assert db_skill_usage.bot_id == bot_id
      assert db_skill_usage.last_usage == Date.utc_today()

      assert Enum.count(DB.list_skill_usages()) == 2
    end

    test "skill_usages_per_user_bot_and_period/2 returns the count for each skill" do
      {:ok, bot1} = DB.create_bot(%{manifest: %{}})
      {:ok, bot2} = DB.create_bot(%{manifest: %{}})
      bot_id = bot1.id
      bot_id_2 = bot2.id
      session_id = "facebook/123456789/987654321"
      session_id_2 = "facebook/123456789/0987654321"
      session_id_3 = "facebook/123456789/1111111111"
      skill_id = "language_detector"
      skill_id_2 = "keyword_1"
      skill_id_3 = "keyword_2"
      {:ok, today} = Date.from_iso8601("2017-12-12")

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: Date.add(today, -(today.day-1)),
        skill_id: skill_id_3, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id_2, user_id: session_id,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_3, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_2, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_2, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: today,
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_3,
        last_usage: today,
        skill_id: skill_id, user_generated: true})

      assert Enum.count(DB.list_skill_usages()) == 8

      skill_usages_today =
        DB.skill_usages_per_user_bot_and_period(bot_id, "today", today)

      assert Enum.count(skill_usages_today) == 1
      assert skill_usages_today == [%{count: 2, skill_id: "language_detector"}]

      skill_usages_this_week =
        DB.skill_usages_per_user_bot_and_period(bot_id, "this_week", today)
        |> Enum.sort(&(&1.skill_id < &2.skill_id))

      assert Enum.count(skill_usages_this_week) == 3
      assert skill_usages_this_week == [
        %{count: 2, skill_id: "keyword_1"},
        %{count: 1, skill_id: "keyword_2"},
        %{count: 3, skill_id: "language_detector"}
      ]

      skill_usages_this_month =
        DB.skill_usages_per_user_bot_and_period(bot_id, "this_month", today)
        |> Enum.sort(&(&1.skill_id < &2.skill_id))

      assert Enum.count(skill_usages_this_month) == 3
      assert skill_usages_this_month == [
        %{count: 2, skill_id: "keyword_1"},
        %{count: 2, skill_id: "keyword_2"},
        %{count: 3, skill_id: "language_detector"}
      ]
    end

    test "active_users_per_bot_and_period/2 returns the active users for a bot" do
      {:ok, bot1} = DB.create_bot(%{manifest: %{}})
      {:ok, bot2} = DB.create_bot(%{manifest: %{}})
      bot_id = bot1.id
      bot_id_2 = bot2.id
      session_id = "facebook/123456789/987654321"
      session_id_2 = "facebook/123456789/0987654321"
      session_id_3 = "facebook/123456789/1111111111"
      session_id_4 = "facebook/123456789/2222222222"
      session_id_5 = "facebook/123456789/3333333333"
      skill_id = "language_detector"
      skill_id_2 = "keyword_1"
      skill_id_3 = "keyword_2"
      {:ok, today} = Date.from_iso8601("2017-12-12")

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_4,
        last_usage: Date.add(today, -(today.day-1)),
        skill_id: skill_id_3, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: Date.add(today, -(today.day-1)),
        skill_id: skill_id_3, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id_2, user_id: session_id,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_3, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_2,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_2, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: Date.add(today, -Date.day_of_week(today)),
        skill_id: skill_id_2, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id,
        last_usage: today,
        skill_id: skill_id, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_3,
        last_usage: today,
        skill_id: skill_id_2, user_generated: true})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_5,
        last_usage: today,
        skill_id: skill_id_2, user_generated: false})

      {:ok, _skill_usage} = DB.create_or_update_skill_usage(
        %{bot_id: bot_id, user_id: session_id_3,
        last_usage: today,
        skill_id: skill_id, user_generated: true})


      assert Enum.count(DB.list_skill_usages()) == 11

      active_users_today = DB.active_users_per_bot_and_period(bot_id, "today", today)
      assert Enum.count(active_users_today) == 2


      active_users_this_week = DB.active_users_per_bot_and_period(bot_id, "this_week", today)
      assert Enum.count(active_users_this_week) == 3


      active_users_this_month = DB.active_users_per_bot_and_period(bot_id, "this_month", today)
      assert Enum.count(active_users_this_month) == 4
    end


    test "create_or_update_messages_per_day_received/1 increments existing messages_per_day with the proper count" do
      bot_id = "d465b43e-e4fa-4255-8bca-1484f062bb12"
      today = Date.utc_today()

      changeset_1 = %{bot_id: bot_id, day: today, received_messages: 1}
      {:ok, messages_per_day} = DB.create_or_update_messages_per_day_received(changeset_1)
      DB.create_or_update_messages_per_day_received(changeset_1)
      DB.create_or_update_messages_per_day_received(changeset_1)
      DB.create_or_update_messages_per_day_received(changeset_1)

      changeset_2 = %{bot_id: bot_id, day: Date.add(today, -1), received_messages: 1}
      {:ok, messages_per_day_2} = DB.create_or_update_messages_per_day_received(changeset_2)
      DB.create_or_update_messages_per_day_received(changeset_2)
      DB.create_or_update_messages_per_day_received(changeset_2)


      db_messages_per_day = DB.get_messages_per_day(messages_per_day.id)
      assert db_messages_per_day.received_messages == 4

      db_messages_per_day_2 = DB.get_messages_per_day(messages_per_day_2.id)
      assert db_messages_per_day_2.received_messages == 3


      assert Enum.count(DB.list_messages_per_day()) == 2
    end


    test "create_or_update_messages_per_day_sent/1 increments existing messages_per_day with the proper count" do
      bot_id = "d465b43e-e4fa-4255-8bca-1484f062bb12"
      today = Date.utc_today()

      changeset_1 = %{bot_id: bot_id, day: today, sent_messages: 1}
      {:ok, messages_per_day} = DB.create_or_update_messages_per_day_sent(changeset_1)
      DB.create_or_update_messages_per_day_sent(changeset_1)
      DB.create_or_update_messages_per_day_sent(changeset_1)

      changeset_2 = %{bot_id: bot_id, day: Date.add(today, -1), sent_messages: 1}
      {:ok, messages_per_day_2} = DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)


      db_messages_per_day = DB.get_messages_per_day(messages_per_day.id)
      assert db_messages_per_day.sent_messages == 3

      db_messages_per_day_2 = DB.get_messages_per_day(messages_per_day_2.id)
      assert db_messages_per_day_2.sent_messages == 5


      assert Enum.count(DB.list_messages_per_day()) == 2
    end


    test "get_bot_messages_per_day_for_period/3 returns the proper count for a bot in a certain period" do
      bot_id = "d465b43e-e4fa-4255-8bca-1484f062bb12"
      today = Date.utc_today()

      changeset_1 = %{bot_id: bot_id, day: today, sent_messages: 1}
      {:ok, _messages_per_day} = DB.create_or_update_messages_per_day_sent(changeset_1)
      DB.create_or_update_messages_per_day_sent(changeset_1)
      DB.create_or_update_messages_per_day_sent(changeset_1)

      changeset_2 = %{bot_id: bot_id, day: Date.add(today, -1), sent_messages: 1}
      {:ok, _messages_per_day} = DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)
      DB.create_or_update_messages_per_day_sent(changeset_2)

      changeset_3 = %{bot_id: bot_id, day: Date.add(today, -1), received_messages: 1}
      {:ok, _messages_per_day} = DB.create_or_update_messages_per_day_received(changeset_3)
      DB.create_or_update_messages_per_day_received(changeset_3)
      DB.create_or_update_messages_per_day_received(changeset_3)
      DB.create_or_update_messages_per_day_received(changeset_3)
      DB.create_or_update_messages_per_day_received(changeset_3)


      bot_messages_per_day = DB.get_bot_messages_per_day_for_period(bot_id, "this_week")

      assert bot_messages_per_day == [%{received_messages: 5, sent_messages: 7}]
    end

    test "get_bot_messages_per_day_for_period/3 returns 0 when there is no record" do
      bot_id = "d465b43e-e4fa-4255-8bca-1484f062bb12"

      bot_messages_per_day = DB.get_bot_messages_per_day_for_period(bot_id, "this_week")

      assert bot_messages_per_day == [%{received_messages: 0, sent_messages: 0}]
    end
  end
end
