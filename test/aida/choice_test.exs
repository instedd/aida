defmodule Aida.ChoiceTest do
  alias Aida.{Bot, Choice, Session, Message}
  import Aida.Expr
  use ExUnit.Case

  @bot %Bot{}
  @session Session.new("1", %{"language" => "en"})

  test "availability" do
    message = Message.new("ok", @bot, @session)

    assert Choice.available?(%Choice{attributes: %{"foo" => 1}}, nil, message)
    refute Choice.available?(%Choice{}, parse("foo = 1"), message)
    refute Choice.available?(%Choice{attributes: %{}}, parse("foo = 1"), message)
    assert Choice.available?(%Choice{}, parse("true()"), message)
    assert Choice.available?(%Choice{attributes: %{}}, parse("true()"), message)
    assert Choice.available?(%Choice{attributes: %{"foo" => 1}}, parse("foo = 1"), message)
    refute Choice.available?(%Choice{}, parse("foo = ${foo}"), message)
    refute Choice.available?(%Choice{}, parse("foo = foo"), message)
    assert Choice.available?(%Choice{attributes: %{"language" => "en"}}, parse("language = ${language}"), message)
    assert Choice.available?(%Choice{name: "foo"}, parse(". = 'foo'"), message)
  end
end
