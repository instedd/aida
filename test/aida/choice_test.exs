defmodule Aida.ChoiceTest do
  alias Aida.{Bot, Skill.Survey.Choice, Message, DB.Session}
  import Aida.Expr
  use Aida.SessionHelper
  use ExUnit.Case

  setup do
    session = new_session("7373f115-e6af-4385-8289-a823b43f727d", %{"language" => "en"})
    message = Message.new("ok", %Bot{}, session)
    [message: message]
  end

  test "availability", %{message: message} do
    assert available?(message)
    assert available?(message, nil, %Choice{attributes: %{}})
    refute available?(message, "foo = 1")
    refute available?(message, "foo = 1", %Choice{attributes: %{}})
    assert available?(message, "true()")
    assert available?(message, "true()", %Choice{attributes: %{}})
    assert available?(message, "foo = 1", %Choice{attributes: %{"foo" => 1}})
    refute available?(message, "foo = ${foo}")
    refute available?(message, "foo = foo")
    assert available?(message, ". = 'foo'", %Choice{name: "foo"})

    assert available?(message, "language = ${language}", %Choice{
             attributes: %{"language" => "en"}
           })
  end

  test "error handling", %{message: message} do
    refute available?(message, "unknown_function()")
    refute available?(message, "${unknown_var}")
    refute available?(message, "unknown_attribute")
  end

  def available?(message, expression \\ nil, choice \\ %Choice{})

  def available?(message, nil, choice) do
    Choice.available?(choice, nil, message)
  end

  def available?(message, expression, choice) do
    Choice.available?(choice, parse(expression), message)
  end
end
