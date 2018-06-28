defmodule Aida.ScheduledMessagesTest do
  alias Aida.{Skill.ScheduledMessages, DB, Message, BotParser, Skill, BotManager, Recurrence}
  alias Aida.DB.{Session, MessageLog}
  alias Aida.Skill.ScheduledMessages.{DelayedMessage, FixedTimeMessage, RecurrentMessage}
  alias Aida.Scheduler
  use Aida.DataCase
  use Aida.TimeMachine

  @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"

  describe "scheduled messages with fixed time" do
    setup :create_bot
    setup :create_session_for_test_channel

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

    test "init doesn't schedule wake_up if the message is scheduled in the past", %{bot: bot} do
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

    test "wake up clears active skills", %{bot: bot, skill: skill, session: %{id: session_id} = session} do
      session
      |> Session.merge(%{
        ".survey/food_preferences" => %{"step" => 3},
        ".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f" => %{
          "question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
        }
      })
      |> Session.save()

      ts = within(hours: 10)

      time_travel(ts) do
        skill |> Skill.wake_up(bot, nil)
        assert_received {:send_message, ["Hello"], ^session_id}
      end

      session = Session.get(session_id)

      assert session |> Session.get_value(".survey/food_preferences") == nil
      assert session |> Session.get_value(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == nil
    end
  end

  describe "schedule messages since last incoming message" do
    setup :create_bot
    setup :create_session_for_test_channel

    setup do
      message1 = %DelayedMessage{delay: 60, message: %{"en" => "Are you there?"}}
      message2 = %DelayedMessage{delay: 1440, message: %{"en" => "Long time no see!"}}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :since_last_incoming_message, messages: [message1, message2]}

      %{skill: skill}
    end

    test "init sorts the messages by delay", %{bot: bot, skill: skill} do
      [m1, m2] = skill.messages
      assert skill == %{skill | messages: [m2, m1]} |> Skill.init(bot)
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
      message_log = MessageLog.create(%{bot_id: bot.id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
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
      MessageLog.create(%{bot_id: bot.id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
      wake_up_ts = within(minutes: 1440)

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        assert_received {:send_message, ["Long time no see!"], ^session_id}
      end

      assert [] = Scheduler.Task.load
    end

    test "wake up too early", %{session_id: session_id, bot: bot, skill: skill} do
      message_log = MessageLog.create(%{bot_id: bot.id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
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
      message_log = MessageLog.create(%{bot_id: bot.id, session_id: session_id, direction: "incoming", content: "Hi", content_type: "text"})
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
      message_log = MessageLog.create(%{bot_id: bot.id, session_id: session.id, direction: "incoming", content: "Hi", content_type: "text"})
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

    test "don't do anything if the session id is invalid", %{bot: bot, skill: skill} do
      skill |> Skill.wake_up(bot, Ecto.UUID.generate)
      refute_received _
      assert [] = Scheduler.Task.load
    end

    test "don't do anything if the session id is nil", %{bot: bot, skill: skill} do
      skill |> Skill.wake_up(bot, nil)
      refute_received _
      assert [] = Scheduler.Task.load
    end

    test "wake up clears active skills", %{
      bot: bot,
      skill: skill,
      session: %{id: session_id} = session
    } do
      session
      |> Session.merge(%{
        ".survey/food_preferences" => %{"step" => 3},
        ".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f" => %{
          "question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
        }
      })
      |> Session.save()

      MessageLog.create(%{
        bot_id: bot.id,
        session_id: session_id,
        direction: "incoming",
        content: "Hi",
        content_type: "text"
      })

      wake_up_ts = within(minutes: 60)

      time_travel(wake_up_ts) do
        skill |> Skill.wake_up(bot, session_id)
        assert_received {:send_message, ["Are you there?"], ^session_id}
      end

      session = Session.get(session_id)

      assert Session.get_value(session, ".survey/food_preferences") == nil
      assert Session.get_value(session, ".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == nil
    end
  end

  describe "scheduled messages with recurrence" do
    setup :create_bot
    setup :create_session_for_test_channel

    setup do
      start = within(hours: 10)
      recurrence = %Recurrence.Daily{start: start, every: 2}
      message = %RecurrentMessage{recurrence: recurrence, message: %{"en" => "Hello"}}
      skill = %ScheduledMessages{id: @skill_id, schedule_type: :recurrent, messages: [message]}
      [skill: skill, start: start]
    end

    test "init schedules a wake_up", %{bot: bot, skill: skill, start: start} do
      assert skill |> Skill.init(bot) == skill

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/0"
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^start, handler: BotManager} = task
    end

    test "send message and schedule the next occurrence", %{bot: bot, skill: skill, session_id: session_id, start: start} do
      time_travel(start) do
        skill |> Skill.wake_up(bot, "0")
        assert_received {:send_message, ["Hello"], ^session_id}
      end

      assert [task] = Scheduler.Task.load
      expected_task_name = "#{bot.id}/#{skill.id}/0"
      expected_ts = Timex.shift(start, days: 2)
      assert %Scheduler.Task{name: ^expected_task_name, ts: ^expected_ts, handler: BotManager} = task
    end

    test "wake up clears active skills", %{bot: bot, skill: skill, session: %{id: session_id} = session, start: start} do
      session
      |> Session.merge(%{
        ".survey/food_preferences" => %{"step" => 3},
        ".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f" => %{
          "question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
        }
      })
      |> Session.save()

      time_travel(start) do
        skill |> Skill.wake_up(bot, "0")
        assert_received {:send_message, ["Hello"], ^session_id}
      end

      session = Session.get(session_id)

      assert session |> Session.get_value(".survey/food_preferences") == nil
      assert session |> Session.get_value(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == nil
    end
  end

  defp create_session_for_test_channel(%{bot: bot}) do
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom)

    session = Session.new({bot.id, "test", "#{pid}"})
      |> Session.merge(%{"language" => "en"})
      |> Session.save

    [session: session, session_id: session.id, session: session]
  end

  defp create_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()
      |> Map.put("languages", ["en"])

    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(db_bot.id, manifest)

    [bot: bot]
  end
end
