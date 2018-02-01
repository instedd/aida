defmodule Aida.ChoiceTest do
  alias Aida.{Bot, Skill.Survey.Choice, Session, Message}
  import Aida.Expr
  use ExUnit.Case

  @session Session.new({"1", "7373f115-e6af-4385-8289-a823b43f727d", %{"language" => "en"}})
  @message Message.new("ok", %Bot{}, @session)

  test "availability" do
    assert available?()
    assert available?(nil, %Choice{attributes: %{}})
    refute available?("foo = 1")
    refute available?("foo = 1", %Choice{attributes: %{}})
    assert available?("true()")
    assert available?("true()", %Choice{attributes: %{}})
    assert available?("foo = 1", %Choice{attributes: %{"foo" => 1}})
    refute available?("foo = ${foo}")
    refute available?("foo = foo")
    assert available?(". = 'foo'", %Choice{name: "foo"})
    assert available?("language = ${language}", %Choice{attributes: %{"language" => "en"}})
  end

  test "error handling" do
    refute available?("unknown_function()")
    refute available?("${unknown_var}")
    refute available?("unknown_attribute")
  end

  def available?(expression \\ nil, choice \\ %Choice{}, message \\ @message)

  def available?(nil, choice, message) do
    Choice.available?(choice, nil, message)
  end

  def available?(expression, choice, message) do
    Choice.available?(choice, parse(expression), message)
  end
end
