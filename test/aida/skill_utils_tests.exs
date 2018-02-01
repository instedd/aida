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

  defp message(_context) do
    [message: Message.new("ok", %Bot{})]
  end
end
