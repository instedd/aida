defmodule Aida.ScheduledMessagesTest do
  alias Aida.{Skill.ScheduledMessages, DelayedMessage, BotParser, Bot, DB, Skill, TestChannel, Session, SessionStore}
  use Aida.DataCase

  describe "scheduled messages" do
    setup do
      %{skill: %ScheduledMessages{
          id: "inactivity_check",
          name: "Inactivity Check",
          schedule_type: "since_last_incoming_message"
        }}
    end

    test "schedules for half the delay interval", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "180"}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(90)
    end

    test "schedules for 24hs as max value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "#{24*60*3}"}]}
      assert ScheduledMessages.delay(skill) == :timer.hours(24)
    end

    test "schedules for 20 minutes as min value", %{skill: skill} do
      skill = %{skill | messages: [%DelayedMessage{delay: "1"}]}
      assert ScheduledMessages.delay(skill) == :timer.minutes(20)
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

      assert_received {:send_message, ["Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?"], "1234"}
    end

    test "sends a message after a month", %{bot: bot} do
      channel = TestChannel.new()
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

      assert_received {:send_message, ["Hey, I didn’t hear from you for the last month, is there anything I can help you with?"], "1234"}
    end

    test "doesn't send a message if the timer is not yet overdue", %{bot: bot} do
      channel = TestChannel.new()
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

    test "doesn't send a message if the reminder has already been sent", %{bot: bot} do
      channel = TestChannel.new()
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
