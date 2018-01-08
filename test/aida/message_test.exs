defmodule Aida.MessageTest do
  alias Aida.{Message, Session}
  use ExUnit.Case

  @bot_id "99fbbf35-d198-474b-9eac-6e27ed9342ed"
  @bot Aida.BotParser.parse!(@bot_id, File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!)

  test "create new incoming message with new session" do
    message = Message.new("Hi!", @bot)
    assert %Message{
      session: %Session{is_new?: true},
      content: "Hi!",
      reply: []
    } = message
  end

  test "create new incoming message with existing session" do
    session = Session.new("9d0694e1-9245-4b9c-9984-7c37b39e1906", %{"foo" => "bar"})
    message = Message.new("Hi!", @bot, session)
    assert %Message{
      session: ^session,
      content: "Hi!",
      reply: []
    } = message
  end

  test "append response to message" do
    message = Message.new("Hi!", @bot) |> Message.respond("Hello")
    assert message.reply == ["Hello"]
  end

  describe "variable interpolation" do
    test "works with strings and numbers" do
      session = Session.new("sid", %{"foo" => 1, "bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "accept whitespace inside brackets" do
      session = Session.new("sid", %{"foo" => 1, "bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${ foo }, bar: ${\tbar\t}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate skill results" do
      session = Session.new("sid", %{"skill/1/foo" => 1, "skill/2/bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate with bot variables" do
      session = Session.new("sid", %{"language" => "en"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food_options}")
      assert message.reply == ["We have barbecue and pasta"]
    end

    test "interpolate recursively" do
      session = Session.new("sid", %{"language" => "en", "first_name" => "John", "last_name" => "Doe", "gender" => "male"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("Hi ${full_name}!")
      assert message.reply == ["Hi Mr. John Doe!"]
    end
  end
end
