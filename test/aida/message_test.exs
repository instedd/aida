defmodule Aida.MessageTest do
  alias Aida.{Message, Session, Message.TextContent}
  use ExUnit.Case

  @bot_id "99fbbf35-d198-474b-9eac-6e27ed9342ed"
  @session_id "f4f81f17-e352-470f-9bfa-9ff163562bcf"
  @session_uuid "3348b2d6-0dc5-4187-b84a-dd50ae116067"
  @bot Aida.BotParser.parse!(@bot_id, File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!)

  test "create new incoming message with new session" do
    message = Message.new("Hi!", @bot)
    assert %Message{
      session: %Session{is_new?: true},
      content: %TextContent{text: "Hi!"},
      reply: []
    } = message
  end

  test "create new incoming message with existing session" do
    session = Session.new({@session_id, @session_uuid, %{"foo" => "bar"}})
    message = Message.new("Hi!", @bot, session)
    assert %Message{
      session: ^session,
      content: %TextContent{text: "Hi!"},
      reply: []
    } = message
  end

  test "append response to message" do
    message = Message.new("Hi!", @bot) |> Message.respond("Hello")
    assert message.reply == ["Hello"]
  end

  describe "variable interpolation" do
    test "works with strings and numbers" do
      session = Session.new({@session_id, @session_uuid, %{"foo" => 1, "bar" => "baz"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "accept whitespace inside brackets" do
      session = Session.new({@session_id, @session_uuid, %{"foo" => 1, "bar" => "baz"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${ foo }, bar: ${\tbar\t}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate skill results" do
      session = Session.new({@session_id, @session_uuid, %{"skill/1/foo" => 1, "skill/2/bar" => "baz"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate with bot variables" do
      session = Session.new({@session_id, @session_uuid, %{"language" => "en"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food_options}")
      assert message.reply == ["We have barbecue and pasta"]
    end

    test "interpolate in a unicode message" do
      session = Session.new({@session_id, @session_uuid, %{"language" => "en"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have “${food_options}”")
      assert message.reply == ["We have “barbecue and pasta”"]
    end

    test "interpolate recursively" do
      session = Session.new({@session_id, @session_uuid, %{"language" => "en", "first_name" => "John", "last_name" => "Doe", "gender" => "male"}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("Hi ${full_name}!")
      assert message.reply == ["Hi Mr. John Doe!"]
    end

    test "interpolate breaks infinite loops" do
      session = Session.new({@session_id, @session_uuid, %{"language" => "en"}})
      devil_var = %Aida.Variable{
        name: "loop_var",
        values: %{
          "en" => "[${loop_var}]"
        }
      }
      bot = %{@bot | variables: [devil_var | @bot.variables]}
      message = Message.new("Hi!", bot, session)
        |> Message.respond("loop_var: ${loop_var}")
      assert message.reply == ["loop_var: [...]"]
    end

    test "interpolates correctly a multiple choice variable with two options" do
      session = Session.new({@session_id, @session_uuid, %{"pepe" => 3, "food" => ["barbecue", "pasta"]}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have barbecue, pasta"]
    end

    test "interpolates correctly a multiple choice variable with more than two options" do
      session = Session.new({@session_id, @session_uuid, %{"pepe" => 3, "food" => ["barbecue", "pasta", "salad"]}})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have barbecue, pasta, salad"]
    end

    test "ignore non existing vars in messages" do
      message = Message.new("Hi!", @bot, Session.new)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have "]
    end
  end
end
