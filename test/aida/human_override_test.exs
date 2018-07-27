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

    test "respond with in_hours_response and push the notification", %{bot: bot, session: session} do
      session = session |> Session.put("first_name", "John")

      with_mock_post do
        response =
          Message.new("table", bot, session)
          |> Bot.chat()

        assert response.reply ==
                 [
                   "Let me ask the manager for availability - I'll come back to you in a few minutes"
                 ]

        assert called(
                 HTTPoison.post(@notifications_url, %{
                   type: :human_override,
                   data: %{message: "table", session_id: session.id, name: "John"}
                 } |> Poison.encode!)
               )
      end
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
