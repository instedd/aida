defmodule Aida.MessageTest do
  alias Aida.{Message, Message.TextContent, Bot}
  alias Aida.DB.{Session}
  use ExUnit.Case
  use Aida.SessionHelper

  @bot_id "99fbbf35-d198-474b-9eac-6e27ed9342ed"
  @session_id "f4f81f17-e352-470f-9bfa-9ff163562bcf"
  @bot Aida.BotParser.parse!(@bot_id, File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!)

  setup do
    initial_session = new_session(@session_id, %{})
    [initial_session: initial_session]
  end

  test "create new incoming message with new session", %{initial_session: initial_session} do
    message = Message.new("Hi!", @bot, initial_session)
    assert %Message{
      session: %Session{is_new: true},
      content: %TextContent{text: "Hi!"},
      reply: []
    } = message
  end

  test "create new incoming message with existing session" do
    session = new_session(@session_id, %{"foo" => "bar"})
    message = Message.new("Hi!", @bot, session)
    assert %Message{
      session: ^session,
      content: %TextContent{text: "Hi!"},
      reply: []
    } = message
  end

  test "append response to message", %{initial_session: initial_session} do
    message = Message.new("Hi!", @bot, initial_session) |> Message.respond("Hello")
    assert message.reply == ["Hello"]
  end

  describe "variable interpolation" do
    test "works with strings and numbers" do
      session = new_session(@session_id, %{"foo" => 1, "bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "accept whitespace inside brackets" do
      session = new_session(@session_id, %{"foo" => 1, "bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${ foo }, bar: ${\tbar\t}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate skill results" do
      session = new_session(@session_id, %{"skill/1/foo" => 1, "skill/2/bar" => "baz"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("foo: ${foo}, bar: ${bar}")
      assert message.reply == ["foo: 1, bar: baz"]
    end

    test "interpolate with bot variables" do
      session = new_session(@session_id, %{"language" => "en"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food_options}")
      assert message.reply == ["We have barbecue and pasta"]
    end

    test "interpolate in a unicode message" do
      session = new_session(@session_id, %{"language" => "en"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have “${food_options}”")
      assert message.reply == ["We have “barbecue and pasta”"]
    end

    test "interpolate recursively" do
      session = new_session(@session_id, %{"language" => "en", "first_name" => "John", "last_name" => "Doe", "gender" => "male"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("Hi ${full_name}!")
      assert message.reply == ["Hi Mr. John Doe!"]
    end

    test "interpolate breaks infinite loops" do
      session = new_session(@session_id, %{"language" => "en"})
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
      session = new_session(@session_id, %{"pepe" => 3, "food" => ["barbecue", "pasta"]})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have barbecue, pasta"]
    end

    test "interpolates correctly a multiple choice variable with more than two options" do
      session = new_session(@session_id, %{"pepe" => 3, "food" => ["barbecue", "pasta", "salad"]})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have barbecue, pasta, salad"]
    end

    test "ignore non existing vars in messages", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("We have ${food}")
      assert message.reply == ["We have "]
    end
  end

  describe "expression interpolation" do
    test "works with basic expression", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("1 + 1 = {{ 1 + 1 }}")
      assert message.reply == ["1 + 1 = 2"]
    end

    test "works with session variables" do
      session = new_session(@session_id, %{"foo" => 3})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("value: {{ ${foo} + 1 }}")
      assert message.reply == ["value: 4"]
    end

    test "works with bot variables" do
      session = new_session(@session_id, %{"age" => 22, "language" => "en"})
      message = Message.new("Hi!", @bot, session)
        |> Message.respond("Food options: {{ ${food_options} }}")
      assert message.reply == ["Food options: barbecue and pasta and a exclusive selection of wines"]
    end

    test "interpolate error message when the variable does not exist", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("Value: {{ ${foo} + 1 }}")
      assert message.reply == ["Value: [ERROR: Could not find variable named 'foo']"]
    end

    test "interpolate error message when the attribute does not exist", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("Value: {{ foo + 1 }}")
      assert message.reply == ["Value: [ERROR: Could not find attribute named 'foo']"]
    end

    test "interpolate error message when the function does not exist", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("Value: {{ foo() }}")
      assert message.reply == ["Value: [ERROR: Could not find function named 'foo']"]
    end

    test "interpolate error message when the expression is invalid", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("Value: {{ *** }}")
      assert message.reply == ["Value: [ERROR: Invalid expression: '***']"]
    end

    test "interpolate two expressions", %{initial_session: initial_session} do
      message = Message.new("Hi!", @bot, initial_session)
        |> Message.respond("foo: {{ 1 + 1 }}, bar: {{ 2 * 4 }}")
      assert message.reply == ["foo: 2, bar: 8"]
    end
  end

  describe "encryption" do
    setup do
      {private, public} = Kcl.generate_key_pair()
      bot = %Bot{public_keys: [public]}
      [bot: bot, private: private]
    end

    test "encrypt the value in the session when requested", %{bot: bot, private: private, initial_session: initial_session} do
      message =
        Message.new("", bot, initial_session)
        |> Message.put_session("name", "John", encrypted: true)

      stored_value = Message.get_session(message, "name")

      assert %{"type" => "encrypted"} = stored_value
      assert "John" == Aida.Crypto.decrypt(stored_value, private) |> Poison.decode!
    end

    test "encrypt a numeric value in the session when requested", %{bot: bot, private: private, initial_session: initial_session} do
      message =
        Message.new("", bot, initial_session)
        |> Message.put_session("age", 20, encrypted: true)

      stored_value = Message.get_session(message, "age")

      assert %{"type" => "encrypted"} = stored_value
      assert 20 == Aida.Crypto.decrypt(stored_value, private) |> Poison.decode!
    end
  end
end
