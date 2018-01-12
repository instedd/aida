defmodule Aida.ScheduledMessagesTest do
  alias Aida.{Skill.ScheduledMessages, BotParser, Bot, DB, Skill, TestChannel, Session, SessionStore, ChannelProvider, BotManager}
  alias Aida.Skill.ScheduledMessages.{DelayedMessage, FixedTimeMessage}
  use Aida.DataCase
  import Mock

  describe "scheduled messages since last incoming message" do
    setup do
      %{skill: %ScheduledMessages{
          id: "inactivity_check",
          name: "Inactivity Check",
          schedule_type: :since_last_incoming_message
        }}
    end

    test "schedules for half the delay interval", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: 180}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(90)
    end

    test "schedules for 24hs as max value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: 24 * 60 *3}]}
      assert ScheduledMessages.delay(skill) == :timer.hours(24)
    end

    test "schedules for 20 minutes as min value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: 1}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(20)
    end
  end

  describe "scheduled messages with fixed time" do
    @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"
    @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"
    @session_id "#{@bot_id}/facebook/1234567890/0987654321"

    setup do
      SessionStore.start_link
      :ok
    end

    test "calculate wake_up delay" do
      now = DateTime.utc_now
      message = %FixedTimeMessage{schedule: now |> Timex.shift(hours: 10)}
      skill = %ScheduledMessages{schedule_type: :fixed_time, messages: [message]}
      assert ScheduledMessages.delay(skill, now) == :timer.hours(10)
    end

    test "init schedules wake_up" do
      bot = %Bot{id: @bot_id}
      message = %FixedTimeMessage{schedule: DateTime.utc_now |> Timex.shift(days: 1)}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :fixed_time, messages: [message]}

      schedule_wake_up_fn = fn(_bot, _skill, delay) ->
        assert_in_delta delay, :timer.hours(24), :timer.seconds(1)
        :ok
      end

      with_mock BotManager, [schedule_wake_up: schedule_wake_up_fn] do
        skill |> Skill.init(bot)
        assert called BotManager.schedule_wake_up(bot, skill, :_)
      end
    end

    test "init doesn't schedule wake_up if the survey is scheduled in the past" do
      bot = %Bot{id: @bot_id}
      message = %FixedTimeMessage{schedule: DateTime.utc_now |> Timex.shift(days: -1)}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :fixed_time, messages: [message]}

      with_mock BotManager, [schedule_wake_up: fn(_bot, _skill, _delay) -> :ok end] do
        skill |> Skill.init(bot)
        refute called BotManager.schedule_wake_up(:_, :_, :_)
      end
    end

    test "send message at fixed time" do
      channel = TestChannel.new
      message = %FixedTimeMessage{message: %{"en" => "Hello"}}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :fixed_time, messages: [message]}
      bot = %Bot{id: @bot_id, skills: [skill], channels: [channel]}

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        Session.new(@session_id, %{"language" => "en"})
        |> Session.save

        Bot.wake_up(bot, @skill_id)

        assert_received {:send_message, ["Hello"], @session_id}
      end
    end
  end

  describe "scheduled bot" do
    @session_id "test/foo/1234"

    setup do
      SessionStore.start_link

      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!

      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)
      {:ok, bot} = Bot.init(bot)

      %{bot: bot}
    end

    test "sends a message after 3 days", %{bot: bot} do
      channel = TestChannel.new()
      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        Session.save(Session.new(@session_id, %{"language" => "en"}))

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: Timex.shift(DateTime.utc_now(), days: -3),
          skill_id: (hd(bot.skills) |> Skill.id()),
          user_generated: true
        })

        Bot.wake_up(bot, "inactivity_check")

        assert_received {:send_message, ["Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?"], @session_id}
      end
    end

    test "sends a message after a month", %{bot: bot} do
      channel = TestChannel.new()

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        Session.save(Session.new(@session_id, %{"language" => "en"}))

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: Timex.shift(DateTime.utc_now(), days: -40),
          skill_id: (hd(bot.skills) |> Skill.id()),
          user_generated: true
        })

        Bot.wake_up(bot, "inactivity_check")

        assert_received {:send_message, ["Hey, I didn’t hear from you for the last month, is there anything I can help you with?"], @session_id}
      end
    end

    test "doesn't send a message if the session is not relevant for the skill" do
      channel = TestChannel.new
      manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      bot = BotParser.parse!(bot.id, manifest)

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        Session.save(Session.new(@session_id, %{"language" => "en"}))

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: Timex.shift(DateTime.utc_now(), days: -40),
          skill_id: (hd(bot.skills) |> Skill.id()),
          user_generated: true
        })

        Bot.wake_up(bot, "inactivity_check")

        refute_received _
      end
    end

    test "doesn't send a message if the timer is not yet overdue", %{bot: bot} do
      channel = TestChannel.new()
      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        Session.save(Session.new(@session_id, %{"language" => "en"}))

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: DateTime.utc_now(),
          skill_id: (hd(bot.skills) |> Skill.id()),
          user_generated: true
        })

        Bot.wake_up(bot, "inactivity_check")

        refute_received _
      end
    end

    test "doesn't send a message if the reminder has already been sent", %{bot: bot} do
      channel = TestChannel.new()
      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        Session.save(Session.new(@session_id, %{"language" => "en"}))

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: Timex.shift(DateTime.utc_now(), days: -3),
          skill_id: (hd(bot.skills) |> Skill.id()),
          user_generated: true
        })

        DB.create_or_update_skill_usage(%{
          bot_id: bot.id,
          user_id: @session_id,
          last_usage: Timex.shift(DateTime.utc_now(), days: -1),
          skill_id: "inactivity_check",
          user_generated: false
        })

        Bot.wake_up(bot, "inactivity_check")

        refute_received _
      end
    end
  end
end
