defmodule Aida.Skill.UtilsTest do
  alias Aida.{
    Bot,
    Message,
    TestSkill,
    Skill.Utils
  }

  use ExUnit.Case
  import Aida.Expr

  setup :message

  test "invalid relevance expresion returns false", %{message: message} do
    refute Utils.is_skill_relevant?(%TestSkill{relevant: parse("unknown_function()")}, message)
    refute Utils.is_skill_relevant?(%TestSkill{relevant: parse("${unknown_var}")}, message)
    refute Utils.is_skill_relevant?(%TestSkill{relevant: parse("unknown_attribute")}, message)
  end

  describe "confidence" do
    setup do
      keywords = %{"en" => ["firstkeyword", "secondkeyword"]}
      session = new_session(Ecto.UUID.generate(), %{"language" => "en"})

      %{session: session, keywords: keywords}
    end

    test "replies with the proper confidence 1", %{session: session, keywords: keywords} do
      message = Message.new("message that says firstkeyword between words", %{}, session)
      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 1 / 6
    end

    test "replies with the proper confidence 2", %{session: session, keywords: keywords} do
      message =
        Message.new("message that says firstkeyword between more words than before", bot, session)

      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 1 / 9
    end

    test "replies with the proper confidence when there is a comma", %{
      session: session,
      keywords: keywords
    } do
      message = Message.new("message that says firstkeyword, and has a comma,", bot, session)
      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 1 / 8
    end

    test "replies with the proper confidence when there is a question mark", %{
      session: session,
      keywords: keywords
    } do
      message =
        Message.new("message that says firstkeyword? yes, and it is a question", bot, session)

      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 1 / 10
    end

    test "does not give an exception with an empty message", %{
      session: session,
      keywords: keywords
    } do
      message = Message.new("", bot, session)
      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 0
    end

    test "returns 0 when there is no match", %{session: session, keywords: keywords} do
      message = Message.new("message that says a lot of different words", bot, session)

      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 0
    end

    test "replies with the proper confidence when there is more than 1 match", %{
      session: session,
      keywords: keywords
    } do
      message =
        Message.new("message that says firstkeyword and also says secondkeyword", bot, session)

      confidence = Utils.confidence_for_keywords(keywords, message)

      assert confidence == 2 / 8
    end
  end

  defp message(_context) do
    [message: Message.new("ok", %Bot{})]
  end
end
