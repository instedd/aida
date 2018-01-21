defmodule Aida.ScheduledMessagesTest do
  alias Aida.{Skill.ScheduledMessages, Message, Bot, DB.MessageLog, Skill, Session, SessionStore, BotManager}
  alias Aida.Skill.ScheduledMessages.{DelayedMessage, FixedTimeMessage}
  alias Aida.Scheduler
  use Aida.DataCase
  use Aida.TimeMachine

  @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"
  @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"

  describe "scheduled messages with fixed time" do
    setup :generate_session_id_for_test_channel
    setup :create_session
    setup :create_bot

    setup do
      message = %FixedTimeMessage{schedule: within(hours: 10), message: %{"en" => "Hello"}}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :fixed_time, messages: [message]}
      [skill: skill]
    end

    test "confidence returns zero", %{bot: bot, skill: skill, session: session} do
      assert skill |> Skill.confidence(Message.new("Hi", bot, session)) == 0
    end

    test "init schedules wake_up", %{bot: bot, skill: skill} do
      skill |> Skill.init(bot)

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ts, handler: BotManager} = task
      assert_in_delta DateTime.diff(ts, within(hours: 10)), 0, 60
    end

    test "init doesn't schedule wake_up if the survey is scheduled in the past", %{bot: bot} do
      message = %FixedTimeMessage{schedule: within(days: -1)}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :fixed_time, messages: [message]}

      skill |> Skill.init(bot)

      assert [] = Scheduler.Task.load
    end

    test "send message", %{bot: bot, skill: skill, session_id: session_id} do
      ts = within(hours: 10)

      time_travel(ts) do
        skill |> Skill.wake_up(bot, nil)
        assert_received {:send_message, ["Hello"], ^session_id}
      end
    end

    test "don't send if the skill is not relevant for the session", %{bot: bot, skill: skill} do
      skill = %{skill | relevant: Aida.Expr.parse("${age} > 18")}
      ts = within(hours: 10)

      time_travel(ts) do
        skill |> Skill.wake_up(bot, nil)
        refute_received _
      end
    end
  end

  describe "schedule messages since last incoming message" do
    setup :generate_session_id_for_test_channel
    setup :create_session
    setup :create_bot

    setup do
      message1 = %DelayedMessage{delay: 60, message: %{"en" => "Are you there?"}}
      message2 = %DelayedMessage{delay: 1440, message: %{"en" => "Long time no see!"}}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :since_last_incoming_message, messages: [message1, message2]}

      %{skill: skill}
    end

    test "find enclosing messages", %{skill: skill} do
      assert {nil, %DelayedMessage{delay: 60}} = ScheduledMessages.find_enclosing_messages(skill, 40)
      assert {%DelayedMessage{delay: 60}, %DelayedMessage{delay: 1440}} = ScheduledMessages.find_enclosing_messages(skill, 60)
      assert {%DelayedMessage{delay: 1440}, nil} = ScheduledMessages.find_enclosing_messages(skill, 1440)
    end

    test "appoint wake up on incoming message", %{session: session, bot: bot, skill: skill} do
      assert skill |> Skill.confidence(Message.new("Hi", bot, session)) == 0

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/#{session.id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ts, handler: BotManager} = task
      assert_in_delta DateTime.diff(ts, within(minutes: 60)), 0, 60
    end

    test "wake up after first delay", %{session_id: session_id, bot: bot, skill: skill} do
      message_log = MessageLog.create(%{bot_id: @bot_id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 60)
      next_ts = Timex.shift(message_log.inserted_at, minutes: 1440)

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        assert_received {:send_message, ["Are you there?"], ^session_id}
      end

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/#{session_id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^next_ts, handler: BotManager} = task
    end

    test "wake up after second delay", %{session_id: session_id, bot: bot, skill: skill} do
      MessageLog.create(%{bot_id: @bot_id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 1440)

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        assert_received {:send_message, ["Long time no see!"], ^session_id}
      end

      assert [] = Scheduler.Task.load
    end

    test "wake up too early", %{session_id: session_id, bot: bot, skill: skill} do
      message_log = MessageLog.create(%{bot_id: @bot_id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 10)
      next_ts = Timex.shift(message_log.inserted_at, minutes: 60)

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        refute_received _
      end

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/#{session_id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^next_ts, handler: BotManager} = task
    end

    test "don't send if the skill is not relevant for the session", %{session_id: session_id, bot: bot, skill: skill} do
      message_log = MessageLog.create(%{bot_id: @bot_id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 60)
      next_ts = Timex.shift(message_log.inserted_at, minutes: 1440)
      skill = %{skill | relevant: Aida.Expr.parse("${age} > 18")}

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        refute_received _
      end

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/#{session_id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^next_ts, handler: BotManager} = task
    end

    test "don't send if the language is not set", %{session: session, bot: bot, skill: skill} do
      message_log = MessageLog.create(%{bot_id: @bot_id, session_id: session.id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 60)
      next_ts = Timex.shift(message_log.inserted_at, minutes: 1440)
      session |> Session.put("language", nil) |> Session.save

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session.id)
        refute_received _
      end

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/#{session.id}"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^next_ts, handler: BotManager} = task
    end
  end

  defp generate_session_id_for_test_channel(_context) do
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom)
    session_id = "#{@bot_id}/test/#{pid}"

    [session_id: session_id]
  end

  defp create_session(%{session_id: session_id}) do
    SessionStore.start_link
    session = Session.new(session_id, %{"language" => "en"})
    session |> Session.save

    [session: session]
  end

  defp create_bot(_context) do
    [bot: %Bot{id: @bot_id}]
  end
end
