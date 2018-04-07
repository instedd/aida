defmodule Aida.BotTest do
  use Aida.DataCase

  alias Aida.{
    Bot,
    BotParser,
    Crypto,
    DataTable,
    DB,
    DB.MessageLog,
    FrontDesk,
    Message,
    Session,
    SessionStore,
    Skill.KeywordResponder,
    TestSkill
  }

  @english_restaurant_greet [
    "Hello, I'm a Restaurant bot",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "I can help you choose a meal that fits your dietary restrictions"
  ]

  @english_not_understood [
    "Sorry, I didn't understand that",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "I can help you choose a meal that fits your dietary restrictions"
  ]

  @english_single_lang_restaurant_greet [
    "Hello, I'm a Restaurant bot",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours"
  ]

  @english_single_lang_not_understood [
    "Sorry, I didn't understand that",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours"
  ]

  @spanish_not_understood [
    "Perdón, no entendí lo que dijiste",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario",
    "Te puedo ayudar a elegir una comida que se adapte a tus restricciones alimentarias"
  ]

  @spanish_restaurant_greet [
    "Hola, soy un bot de Restaurant",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario",
    "Te puedo ayudar a elegir una comida que se adapte a tus restricciones alimentarias"
  ]

  @language_selection_text "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'"

  @language_selection_speech [ @language_selection_text ]

  @session_uuid "ab11d25c-85c1-41c7-910a-3e64fa13cbbe"

  setup do
    SessionStore.start_link
    :ok
  end

  describe "single language bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "replies with greeting on the first message", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @english_single_lang_restaurant_greet
    end

    test "replies with explanation when message not understood and is not the first message", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("foobar", bot, response.session))
      assert output.reply == @english_single_lang_not_understood
    end

    test "replies with explanation when message has unknown content and is not the first message", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new_unknown(bot, response.session))
      assert output.reply == @english_single_lang_not_understood
    end

    test "replies with clarification when message matches more than one skill and similar confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("food hours", bot, response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For menu options, write 'menu'",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with the skill with more confidence when message matches more than one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("Want time food hours", bot, response.session))
      assert output.reply == [
        "We are open every day from 7pm to 11pm"
      ]
    end

    test "replies with clarification when message matches only one skill but with low confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("I want to know the opening hours for this restaurant", bot, response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with skill when message matches one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("hours", bot, response.session))
      assert output.reply == [
        "We are open every day from 7pm to 11pm"
      ]
    end
  end

  describe "multiple languages bot" do
    setup :create_manifest_bot

    test "replies with language selection on the first message", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech
    end

    test "selects language when the user sends 'english'", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español'", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "after selecting language it doesn't switch when a phrase includes a different one", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("no se hablar english", bot, output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == @spanish_not_understood

    end

    test "after selecting language only switches when just the new language is received", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("english", bot, output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == []

      input4 = Message.new("hello", bot, output3.session)
      output4 = bot |> Bot.chat(input4)
      assert output4.reply == @english_not_understood
    end

    test "selects language when the user sends 'english' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english please", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Quiero hablar en español por favor", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects language when the user sends 'español' followed by a question mark", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Puedo hablar en español?", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects the first language when the user sends more than one", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english or spanish o inglés", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "replies language selection when the user selects a not available language ", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("português", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == ["Desculpe, eu não falo Português para agora"] ++ @language_selection_speech
    end

    test "reset language when the session already has a language not understood by the bot", %{bot: bot} do
      session = Session.new({"sid", @session_uuid, %{"language" => "jp"}})
      Session.save(session)
      input = Message.new("Hi!", bot, session)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech
      assert output |> Message.get_session("language") == nil
    end
  end

  describe "bot with skill relevances" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
        |> Poison.decode!
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "introduction message includes only relevant skills", %{bot: bot} do
      session = Session.new({"sid", @session_uuid, %{"language" => "en", "age" => 14}})
      Session.save(session)
      input = Message.new("Hi!", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end

    test "only relevant skills receive the message", %{bot: bot} do
      session = Session.new({"sid", @session_uuid, %{"language" => "en", "age" => 14}})
      Session.save(session)
      input = Message.new("menu", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end

    test "relevance expressions containing undefined variables are considered false", %{bot: bot} do
      session = Session.new({"sid", @session_uuid, %{"language" => "en"}})
      Session.save(session)
      input = Message.new("menu", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end
  end

  describe "bot variables" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "lookup", %{bot: bot} do
      session = Session.new("sid")
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta"
    end

    test "lookup non existing variable returns nil", %{bot: bot} do
      session = Session.new("sid")
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "foo")
      assert value == nil
    end

    test "lookup variabe evaluate overrides", %{bot: bot} do
      session = Session.new({"sid", @session_uuid, %{"age" => 20}})
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta and a exclusive selection of wines"

      session = Session.new({"sid", @session_uuid, %{"age" => 15}})
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta"
    end

    test "lookup from eval", %{bot: bot} do
      expr_context = Message.new("foo", bot, Session.new({"sid", @session_uuid, %{"language" => "en"}}))
        |> Message.expr_context(lookup_raises: true)

      value = Aida.Expr.parse("${food_options}")
        |> Aida.Expr.eval(expr_context)

      assert value == "barbecue and pasta"
    end

    test "ignore non existing vars in messages", %{bot: bot} do
      bot = %Bot{
        id: bot.id,
        languages: ["en"],
        skills: [
          %KeywordResponder{
            explanation: %{ "en" => "" },
            clarification: %{ "en" => "" },
            id: "id",
            bot_id: bot.id,
            name: "Distribution days",
            keywords: %{
              "en" => ["days"]
            },
            response: %{
              "en" => "We will deliver ${foo}"
            }
          }
        ]
      }

      output = bot |> Bot.chat(Message.new("days", bot))
      assert output.reply == [
        "We will deliver "
      ]
    end
  end

  describe "data_tables" do
    setup do
      {:ok, db_bot} = DB.create_bot(%{manifest: %{}})

      bot = %Bot{
        id: db_bot.id,
        languages: ["en"],
        skills: [
          %KeywordResponder{
            explanation: %{ "en" => "" },
            clarification: %{ "en" => "" },
            id: "id",
            bot_id: db_bot.id,
            name: "Distribution days",
            keywords: %{
              "en" => ["days"]
            },
            response: %{
              "en" => "We will deliver {{ lookup('Kakuma 1', 'Distribution_days', 'Day')}}"
            }
          }
        ],
        data_tables: [
          %DataTable{
            name: "Distribution_days",
            columns: ["Location", "Day", "Distribution_place", "# of distribution posts"],
            data: [
              ["Kakuma 1", "Next Thursday", "In front of the square", 2],
              ["Kakuma 2", "Next Friday", "In front of the church", 1],
              ["Kakuma 3", "Next Saturday", "In front of the distribution centre", 3]
            ]
          }
        ]
      }

      %{bot: bot}
    end

    test "lookup from eval", %{bot: bot} do
      expr_context = Message.new("foo", bot, Session.new({"sid", @session_uuid, %{"key" => "Kakuma 2"}}))
        |> Message.expr_context(lookup_raises: true)

      value = Aida.Expr.parse("lookup(${key}, 'Distribution_days', 'Day')")
        |> Aida.Expr.eval(expr_context)

      assert value == "Next Friday"

      value = Aida.Expr.parse("lookup(${key}, 'Distribution_days', 'Distribution_place')")
        |> Aida.Expr.eval(expr_context)

      assert value == "In front of the church"
    end

    test "interpolate expression", %{bot: bot} do
      output = bot |> Bot.chat(Message.new("days", bot))
      assert output.reply == [
        "We will deliver Next Thursday"
      ]
    end
  end

  describe "attributes" do
    setup do
      {:ok, db_bot} = DB.create_bot(%{manifest: %{}})
      bot = %Bot{
        id: db_bot.id,
        languages: ["en"],
        skills: [
          %KeywordResponder{
            explanation: %{ "en" => "" },
            clarification: %{ "en" => "" },
            id: "id",
            bot_id: db_bot.id,
            name: "Distribution",
            keywords: %{
              "en" => ["days"]
            },
            response: %{
              "en" => "We will deliver {{ attribute }}"
            }
          }
        ]
      }

      %{bot: bot}
    end

    test "display errors in messages", %{bot: bot} do
      output = bot |> Bot.chat(Message.new("days", bot))
      assert output.reply == [
        "We will deliver [ERROR: Could not find attribute named 'attribute']"
      ]
    end
  end

  describe "encryption" do
    setup do
      {private, public} = Kcl.generate_key_pair()
      bot = %Bot{public_keys: [public]}
      [bot: bot, private: private]
    end

    test "encrypt a value", %{bot: bot, private: private} do
      value = Bot.encrypt(bot, "Hello")
      assert %{"type" => "encrypted"} = value
      assert "Hello" == Aida.Crypto.decrypt(value, private)
    end
  end

  describe "logging" do
    setup :create_manifest_bot
    setup :generate_session_id_for_test_channel
    setup :create_session

    test "logs messages on chat", %{bot: bot, session: session} do
      input = Message.new("Hi!", bot, session)

      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      [incoming_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "incoming"))

      assert incoming_message_log.session_id == session.id
      assert incoming_message_log.bot_id == bot.id
      assert incoming_message_log.content == "Hi!"

      [outgoing_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "outgoing"))

      assert outgoing_message_log.session_id == session.id
      assert outgoing_message_log.bot_id == bot.id
      assert outgoing_message_log.content == @language_selection_text
    end

    test "logs on send_message", %{bot: bot, session: session} do
      message =
        Message.new("", bot, session)
        |> Message.respond("howdy!")

      Bot.send_message(message)

      [outgoing_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "outgoing"))

      assert outgoing_message_log.session_id == session.id
      assert outgoing_message_log.bot_id == bot.id
      assert outgoing_message_log.content == "howdy!"
    end

    test "encrypt incoming message logs", %{bot: bot, session: session} do
      {private, public} = Kcl.generate_key_pair()
      bot = %{bot | skills: [ %TestSkill{encrypt: true} ], languages: ["en"], public_keys: [public]}

      input =
        Message.new("Hi!", bot, session)
        |> Message.put_session("language", "en")

      output = bot |> Bot.chat(input)
      assert output.reply == ["This is a test"]

      [incoming_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "incoming"))

      assert incoming_message_log.content_type == "encrypted"
      assert incoming_message_log.session_id == session.id
      assert incoming_message_log.bot_id == bot.id
      json = incoming_message_log.content |> Poison.decode!

      assert Crypto.decrypt(json, private) |> Poison.decode! == %{"content_type" => "text", "content" => "Hi!"}

      [outgoing_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "outgoing"))

      assert outgoing_message_log.session_id == session.id
      assert outgoing_message_log.bot_id == bot.id
      assert outgoing_message_log.content == "This is a test"
    end
  end

  describe "empty clarification" do
    setup do
      {:ok, db_bot} = DB.create_bot(%{manifest: %{}})

      bot = %Bot{
        id: db_bot.id,
        languages: ["en"],
        front_desk: %FrontDesk{
          threshold: 0.5,
          greeting: %{ "en" => "Hello, I'm a Restaurant bot" },
          introduction: %{ "en" => "I can do a number of things" },
          not_understood: %{ "en" => "Sorry, I didn't understand that" },
          clarification: %{ "en" => "I'm not sure exactly what you need." }
        },
        skills: [
          %KeywordResponder{
            explanation: %{ "en" => "" },
            clarification: %{ "en" => "" },
            id: "id",
            bot_id: db_bot.id,
            name: "Food",
            keywords: %{
              "en" => ["food"]
            },
            response: %{
              "en" => "Steak"
            }
          },
          %KeywordResponder{
            explanation: %{ "en" => "" },
            clarification: %{ "en" => "" },
            id: "id",
            bot_id: db_bot.id,
            name: "Hours",
            keywords: %{
              "en" => ["hours"]
            },
            response: %{
              "en" => "Noon"
            }
          }
        ]
      }

      %{bot: bot}
    end

    test "replies with no explanation message if the skills have empty explanation", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("foobar", bot, response.session))
      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things"
      ]
    end

    test "replies with no clarification when message matches more than one skill and similar confidence but they have no clarification", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("food hours", bot, response.session))
      assert output.reply == [
        "I'm not sure exactly what you need."
      ]
    end
  end

  defp create_manifest_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()

    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)

    [bot: bot]
  end

  defp generate_session_id_for_test_channel(%{bot: bot}) do
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom)
    session_id = "#{bot.id}/test/#{pid}"

    [session_id: session_id]
  end

  defp create_session(%{session_id: session_id}) do
    SessionStore.start_link
    session = Session.new({session_id, @session_uuid, %{}})
    session |> Session.save

    [session: session]
  end
end
