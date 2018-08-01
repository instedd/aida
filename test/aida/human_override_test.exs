defmodule Aida.HumanOverrideTest do
  alias Aida.{Bot, BotParser, DB, Message, Skill}
  use Aida.DataCase
  use Aida.SessionHelper
  import Mock

  defmacro with_mock_post(do: yield) do
    quote do
      with_mock HTTPoison, post: fn _, _ -> {:ok, %{status_code: 200}} end do
        unquote(yield)
      end
    end
  end

  @human_override_id "human_override_skill"
  @notifications_url "https://example.com/1"

  describe "human override confidence" do
    setup :create_bot

    test "replies with the proper confidence 1", %{bot: bot, session: session} do
      message = Message.new("message that says available between words", bot, session)

      confidence = get_confidence_from_skill_id(bot.skills, message, @human_override_id)

      assert confidence == 1 / 6
    end
  end

  describe "notifications" do
    setup :create_bot

    @in_hours_response "Let me ask the manager for availability - I'll come back to you in a few minutes"
    @off_hours_response "Sorry, but we are not taking reservations right now. I'll let you know about tomorrow."

    def expect_reply_at(timestamp, expected_response, %{bot: bot, session: session}) do
      {:ok, parsed_time, _offset} = DateTime.from_iso8601(timestamp)
      session = session |> Session.put("first_name", "John")
      with_mock_post do
        response =
          Message.new("table", bot, session, parsed_time)
          |> Bot.chat()

        assert response.reply == [ expected_response ]

        assert called(
                 HTTPoison.post(@notifications_url, %{
                   type: :human_override,
                   data: %{message: "table", session_id: session.id, bot_id: bot.id, name: "John"}
                 } |> Poison.encode!)
               )
      end
    end

    test "respond with in_hours_response and push the notification", context do
      [
        "2018-07-23T14:00:00-03:00", # monday in first time slot
        "2018-07-23T20:01:00-03:00", # monday in second time slot - without explicit end
        "2018-07-24T02:50:00-03:00", # tuesday's time slot with implicit start
        "2018-07-25T02:50:00-03:00", # wednesday all day
        "2018-07-25T10:50:00-03:00", # wednesday all day
        "2018-07-25T23:50:00-03:00", # wednesday all day
        "2018-07-26T02:50:00Z", # still wednesday, but in a different timezone
      ] |> Enum.each(fn timestamp -> expect_reply_at timestamp, @in_hours_response, context end)
    end

    test "respond with off_hours_response and push the notification", context do
      [
        "2018-07-23T09:12:00-03:00", # monday before first time slot
        "2018-07-23T19:00:00-03:00", # monday between time slots
        "2018-07-24T03:05:00-03:00", # tuesday after end time
        "2018-07-26T02:50:00-03:00", # no slots on thursday
        "2018-07-26T10:50:00-03:00", # no slots on thursday
        "2018-07-26T23:50:00-03:00", # no slots on thursday
        "2018-07-25T23:50:00-06:00", # already thursday in our timezone
      ] |> Enum.each(fn timestamp -> expect_reply_at timestamp, @off_hours_response, context end)
    end
  end

  defp get_confidence_from_skill_id(skills, message, id) do
    skills =
      skills
      |> Enum.filter(fn skill ->
        skill.id == id
      end)

    case skills do
      [skill] ->
        Skill.confidence(skill, message)

      _ ->
        assert false
    end
  end

  defp create_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest_with_human_override.json")
      |> Poison.decode!()
      |> Map.put("notifications_url", @notifications_url)

    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)
    session = new_session(Ecto.UUID.generate(), %{"language" => "en"}, bot.id)

    [bot: bot, session: session]
  end
end
