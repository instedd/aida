defmodule Aida.BotTest do
  use Aida.DataCase
  use Aida.SessionHelper
  alias Aida.DB.{Session}
  import Mock

  alias Aida.{
    Bot,
    BotParser,
    Crypto,
    DataTable,
    DB,
    ErrorLog,
    FrontDesk,
    Message,
    Skill.KeywordResponder,
    TestSkill,
    Variable,
    Repo
  }

  alias Aida.DB.{MessageLog, Session}

  @english_restaurant_greet [
    "Hello, I'm a Restaurant bot",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "I can help you choose a meal that fits your dietary restrictions",
    "Send UNSUBSCRIBE to stop receiving messages"
  ]

  @english_not_understood [
    "Sorry, I didn't understand that",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "I can help you choose a meal that fits your dietary restrictions",
    "Send UNSUBSCRIBE to stop receiving messages"
  ]

  @english_single_lang_restaurant_greet [
    "Hello, I'm a Restaurant bot",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "Send UNSUBSCRIBE to stop receiving messages"
  ]

  @english_single_lang_not_understood [
    "Sorry, I didn't understand that",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours",
    "Send UNSUBSCRIBE to stop receiving messages"
  ]

  @spanish_not_understood [
    "Perdón, no entendí lo que dijiste",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario",
    "Te puedo ayudar a elegir una comida que se adapte a tus restricciones alimentarias",
    "Enviá DESUSCRIBIR para dejar de recibir mensajes"
  ]

  @spanish_restaurant_greet [
    "Hola, soy un bot de Restaurant",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario",
    "Te puedo ayudar a elegir una comida que se adapte a tus restricciones alimentarias",
    "Enviá DESUSCRIBIR para dejar de recibir mensajes"
  ]

  @language_selection_text "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'"

  @language_selection_speech [@language_selection_text]

  @provider "facebook"
  @provider_key "1234/5678"

  describe "single language bot" do
    setup do
      manifest =
        File.read!("test/fixtures/valid_manifest_single_lang.json")
        |> Poison.decode!()

      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)
      s = Session.new({bot.id, @provider, @provider_key})
      initial_session = Repo.get(Session, s.id)

      %{bot: bot, initial_session: initial_session}
    end

    test "forward text messages", %{
      bot: bot,
      initial_session: initial_session
    } do
      forward_messages_id = Ecto.UUID.generate()
      session = initial_session |> Session.put(".forward_messages_id", forward_messages_id)

      with_mock HTTPoison,
        post: fn _url, _body -> {:ok, %HTTPoison.Response{status_code: 200}} end do
        %{reply: reply} = Message.new("a message", bot, session) |> Bot.chat()

        assert length(reply) == 0

        assert MessageLog
               |> Repo.all()
               |> Enum.filter(&(&1.direction == "outgoing"))
               |> Enum.count() == 0

        assert MessageLog
               |> Repo.all()
               |> Enum.filter(&(&1.direction == "incoming"))
               |> Enum.count() == 1

        assert called(
                 HTTPoison.post(
                   "#{bot.notifications_url}/messages/#{forward_messages_id}",
                   %{type: "text", direction: "uto", content: "a message"}
                   |> Poison.encode!()
                 )
               )
      end
    end

    test "does not forward other message types", %{
      bot: bot,
      initial_session: initial_session
    } do
      forward_messages_id = Ecto.UUID.generate()
      session = initial_session |> Session.put(".forward_messages_id", forward_messages_id)

      with_mock HTTPoison,
        post: fn _url, _body -> {:ok, %HTTPoison.Response{status_code: 200}} end do
        Message.new_unknown(bot, session) |> Bot.chat()

        assert not called(
                 HTTPoison.post(
                   "#{bot.notifications_url}/messages/#{forward_messages_id}",
                   %{type: "text", direction: "uto", content: "a message"}
                   |> Poison.encode!()
                 )
               )
      end
    end

    test "replies with greeting on the first message", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @english_single_lang_restaurant_greet
    end

    test "replies with explanation when message not understood and is not the first message", %{
      bot: bot,
      initial_session: initial_session
    } do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("foobar", bot, response.session))
      assert output.reply == @english_single_lang_not_understood
    end

    test "replies with explanation when message has unknown content and is not the first message",
         %{bot: bot, initial_session: initial_session} do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new_unknown(bot, response.session))
      assert output.reply == @english_single_lang_not_understood
    end

    test "replies with clarification when message matches more than one skill and similar confidence",
         %{bot: bot, initial_session: initial_session} do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("food hours", bot, response.session))

      assert output.reply == [
               "I'm not sure exactly what you need.",
               "For menu options, write 'menu'",
               "For opening hours say 'hours'"
             ]
    end

    test "replies with the skill with more confidence when message matches more than one skill",
         %{bot: bot, initial_session: initial_session} do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("Want time food hours", bot, response.session))

      assert output.reply == [
               "We are open every day from 7pm to 11pm"
             ]
    end

    test "replies with clarification when message matches only one skill but with low confidence",
         %{bot: bot, initial_session: initial_session} do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))

      output =
        Bot.chat(
          Message.new(
            "I want to know the opening hours for this restaurant",
            bot,
            response.session
          )
        )

      assert output.reply == [
               "I'm not sure exactly what you need.",
               "For opening hours say 'hours'"
             ]
    end

    test "replies with skill when message matches one skill", %{
      bot: bot,
      initial_session: initial_session
    } do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("hours", bot, response.session))

      assert output.reply == [
               "We are open every day from 7pm to 11pm"
             ]
    end
  end

  describe "multiple languages bot" do
    setup :create_manifest_bot

    test "replies with language selection on the first message", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech
    end

    test "selects language when the user sends 'english'", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", bot, output.session)
      output2 = Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español'", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "after selecting language it doesn't switch when a phrase includes a different one", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("no se hablar english", bot, output2.session)
      output3 = Bot.chat(input3)
      assert output3.reply == @spanish_not_understood
    end

    test "after selecting language only switches when just the new language is received", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("english", bot, output2.session)
      output3 = Bot.chat(input3)
      assert output3.reply == []

      input4 = Message.new("hello", bot, output3.session)
      output4 = Bot.chat(input4)
      assert output4.reply == @english_not_understood
    end

    test "selects language when the user sends 'english' in a long sentence", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english please", bot, initial_session)
      output2 = Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español' in a long sentence", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Quiero hablar en español por favor", bot, initial_session)
      output2 = Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects language when the user sends 'español' followed by a question mark", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Puedo hablar en español?", bot, initial_session)
      output2 = Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects the first language when the user sends more than one", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english or spanish o inglés", bot, initial_session)
      output2 = Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "replies language selection when the user selects a not available language ", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("português", bot, output.session)
      output2 = Bot.chat(input2)

      assert output2.reply ==
               ["Desculpe, eu não falo Português para agora"] ++ @language_selection_speech
    end

    test "reset language when the session already has a language not understood by the bot", %{
      bot: bot,
      initial_session: initial_session
    } do
      session = initial_session |> Session.merge(%{"language" => "jp"})
      input = Message.new("Hi!", bot, session)
      output = Bot.chat(input)
      assert output.reply == @language_selection_speech
      assert output |> Message.get_session("language") == nil
    end
  end

  describe "bot with skill relevances" do
    setup do
      manifest =
        File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
        |> Poison.decode!()

      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)
      initial_session = Session.new({bot.id, @provider, @provider_key})
      %{initial_session | is_new: false} |> Session.save()

      %{bot: bot, initial_session: initial_session}
    end

    test "introduction message includes only relevant skills", %{
      bot: bot,
      initial_session: initial_session
    } do
      session =
        Session.get(initial_session.id) |> Session.merge(%{"language" => "en", "age" => 14})

      input = Message.new("Hi!", bot, session)
      output = Bot.chat(input)

      assert output.reply == [
               "Sorry, I didn't understand that",
               "I can do a number of things",
               "I can give you information about our opening hours",
               "Send UNSUBSCRIBE to stop receiving messages"
             ]
    end

    test "only relevant skills receive the message", %{bot: bot, initial_session: initial_session} do
      session =
        Session.get(initial_session.id) |> Session.merge(%{"language" => "en", "age" => 14})

      input = Message.new("menu", bot, session)

      output = Bot.chat(input)

      assert output.reply == [
               "Sorry, I didn't understand that",
               "I can do a number of things",
               "I can give you information about our opening hours",
               "Send UNSUBSCRIBE to stop receiving messages"
             ]
    end

    test "relevance expressions containing undefined variables are considered false", %{
      bot: bot,
      initial_session: initial_session
    } do
      session = Session.get(initial_session.id) |> Session.merge(%{"language" => "en"})
      input = Message.new("menu", bot, session)
      output = Bot.chat(input)

      assert output.reply == [
               "Sorry, I didn't understand that",
               "I can do a number of things",
               "I can give you information about our opening hours",
               "Send UNSUBSCRIBE to stop receiving messages"
             ]
    end
  end

  describe "bot variables" do
    setup do
      manifest =
        File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!()

      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)
      initial_session = Session.new({bot.id, @provider, @provider_key})

      %{bot: bot, initial_session: initial_session}
    end

    test "lookup", %{bot: bot, initial_session: initial_session} do
      message = Message.new("foo", bot, initial_session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta"
    end

    test "lookup non existing variable returns nil", %{bot: bot, initial_session: initial_session} do
      message = Message.new("foo", bot, initial_session)
      value = bot |> Bot.lookup_var(message, "foo")
      assert value == nil
    end

    test "lookup variabe evaluate overrides", %{bot: bot, initial_session: initial_session} do
      session = initial_session |> Session.merge(%{"age" => 20})
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta and a exclusive selection of wines"

      session = initial_session |> Session.merge(%{"age" => 15})
      message = Message.new("foo", bot, session)
      value = bot |> Bot.lookup_var(message, "food_options")
      assert value["en"] == "barbecue and pasta"
    end

    test "lookup from eval", %{bot: bot, initial_session: initial_session} do
      expr_context =
        Message.new("foo", bot, initial_session |> Session.merge(%{"language" => "en"}))
        |> Message.expr_context(lookup_raises: true)

      value =
        Aida.Expr.parse("${food_options}")
        |> Aida.Expr.eval(expr_context)

      assert value == "barbecue and pasta"
    end

    test "ignore non existing vars in messages", %{initial_session: initial_session, bot: bot} do
      bot = %Bot{
        id: bot.id,
        languages: ["en"],
        skills: [
          %KeywordResponder{
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
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

      output = Bot.chat(Message.new("days", bot, initial_session))

      assert output.reply == [
               "We will deliver "
             ]
    end

    test "recursive var lookup raises stack overflow and returns without crashing", %{
      initial_session: initial_session,
      bot: bot
    } do
      bot = %Bot{
        id: bot.id,
        languages: ["en"],
        skills: [
          %KeywordResponder{
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
            id: "id",
            bot_id: bot.id,
            name: "Mr or Ms",
            keywords: %{
              "en" => ["hi"]
            },
            response: %{
              "en" => "I'll call you ${title}"
            }
          }
        ],
        variables: [
          %Variable{
            name: "title",
            values: %{
              "en" => "",
              "es" => ""
            },
            overrides: [
              %Variable.Override{
                relevant: Aida.Expr.parse("${title} = 'male'"),
                values: %{
                  "en" => "Mr.",
                  "es" => "Sr."
                }
              },
              %Variable.Override{
                relevant: Aida.Expr.parse("${title} = 'female'"),
                values: %{
                  "en" => "Ms.",
                  "es" => "Sra."
                }
              }
            ]
          }
        ]
      }

      Process.info(self(), :current_stacktrace)

      output = Bot.chat(Message.new("hi", bot, initial_session))

      assert output.reply == [
               "I'll call you "
             ]

      log = ErrorLog |> Repo.all() |> hd()
      assert log.message == "Variable 'title' has a recursive definition"
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
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
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

      initial_session = Session.new({bot.id, @provider, @provider_key})

      %{bot: bot, initial_session: initial_session}
    end

    test "lookup from eval", %{bot: bot, initial_session: initial_session} do
      expr_context =
        Message.new("foo", bot, initial_session |> Session.merge(%{"key" => "Kakuma 2"}))
        |> Message.expr_context(lookup_raises: true)

      value =
        Aida.Expr.parse("lookup(${key}, 'Distribution_days', 'Day')")
        |> Aida.Expr.eval(expr_context)

      assert value == "Next Friday"

      value =
        Aida.Expr.parse("lookup(${key}, 'Distribution_days', 'Distribution_place')")
        |> Aida.Expr.eval(expr_context)

      assert value == "In front of the church"
    end

    test "interpolate expression", %{bot: bot, initial_session: initial_session} do
      output = Bot.chat(Message.new("days", bot, initial_session))

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
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
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

      initial_session = Session.new({bot.id, @provider, @provider_key})

      %{bot: bot, initial_session: initial_session}
    end

    test "display errors in messages", %{bot: bot, initial_session: initial_session} do
      output = Bot.chat(Message.new("days", bot, initial_session))

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
    setup :generate_session_for_test_channel

    test "logs messages on chat", %{bot: bot, session: session} do
      input = Message.new("Hi!", bot, session)

      output = Bot.chat(input)
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
      bot = %{bot | skills: [%TestSkill{encrypt: true}], languages: ["en"], public_keys: [public]}

      input =
        Message.new("Hi!", bot, session)
        |> Message.put_session("language", "en")

      output = Bot.chat(input)
      assert output.reply == ["This is a test"]

      [incoming_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "incoming"))

      assert incoming_message_log.content_type == "encrypted"
      assert incoming_message_log.session_id == session.id
      assert incoming_message_log.bot_id == bot.id
      json = incoming_message_log.content |> Poison.decode!()

      assert Crypto.decrypt(json, private) |> Poison.decode!() == %{
               "content_type" => "text",
               "content" => "Hi!"
             }

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
          greeting: %{"en" => "Hello, I'm a Restaurant bot"},
          introduction: %{"en" => "I can do a number of things"},
          not_understood: %{"en" => "Sorry, I didn't understand that"},
          clarification: %{"en" => "I'm not sure exactly what you need."},
          unsubscribe: %{
            introduction_message: %{
              "en" => "Send UNSUBSCRIBE to stop receiving messages",
              "es" => "Enviá DESUSCRIBIR para dejar de recibir mensajes"
            },
            keywords: %{
              "en" => ["UNSUBSCRIBE"],
              "es" => ["DESUSCRIBIR"]
            },
            acknowledge_message: %{
              "en" => "I won't send you any further messages",
              "es" => "No te enviaré más mensajes"
            }
          }
        },
        skills: [
          %KeywordResponder{
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
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
            explanation: %{"en" => ""},
            clarification: %{"en" => ""},
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

      initial_session = Session.new({bot.id, @provider, @provider_key})

      %{bot: bot, initial_session: initial_session}
    end

    test "replies with no explanation message if the skills have empty explanation", %{
      bot: bot,
      initial_session: initial_session
    } do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("foobar", bot, response.session))

      assert output.reply == [
               "Sorry, I didn't understand that",
               "I can do a number of things",
               "Send UNSUBSCRIBE to stop receiving messages"
             ]
    end

    test "replies with no clarification when message matches more than one skill and similar confidence but they have no clarification",
         %{bot: bot, initial_session: initial_session} do
      response = Bot.chat(Message.new("Hi!", bot, initial_session))
      output = Bot.chat(Message.new("food hours", bot, response.session))

      assert output.reply == [
               "I'm not sure exactly what you need."
             ]
    end
  end

  describe "log errors" do
    setup :create_manifest_bot
    setup :generate_session_for_test_channel

    test "when there is a missing variable", %{bot: bot, session: session} do
      bot = Updater.update(bot, [:skills, 0, :explanation], "foo: ${foo}")
      ld_skill = bot.skills |> Enum.at(0)

      Message.new("Hi!", bot, session)
      |> Bot.chat()

      assert [error_log] = ErrorLog |> Repo.all()
      assert error_log.bot_id == bot.id
      assert error_log.session_id == session.id
      assert error_log.skill_id == ld_skill |> Aida.Skill.id()
      assert error_log.message == "Variable 'foo' was not found"
    end

    test "when the expression contains an error", %{bot: bot, session: session} do
      bot = Updater.update(bot, [:skills, 0, :explanation], "foo: {{ bar }}")
      ld_skill = bot.skills |> Enum.at(0)

      Message.new("Hi!", bot, session)
      |> Bot.chat()

      assert [error_log] = ErrorLog |> Repo.all()
      assert error_log.bot_id == bot.id
      assert error_log.session_id == session.id
      assert error_log.skill_id == ld_skill |> Aida.Skill.id()
      assert error_log.message == "Could not find attribute named 'bar'"
    end

    test "when post_notification_message fails", %{bot: bot, session: session} do
      forward_messages_id = Ecto.UUID.generate()
      session = session |> Session.put(".forward_messages_id", forward_messages_id)

      response = {:ok, %HTTPoison.Response{status_code: 500}}

      with_mock HTTPoison,
        post: fn _url, _body -> response end do
        Message.new("a message", bot, session) |> Bot.chat()

        [error_log] = ErrorLog |> Repo.all()
        assert error_log.bot_id == bot.id
        assert error_log.session_id == session.id

        assert error_log.message == "Error forwarding message to remote endpoint"
      end
    end
  end

  describe "do not disturb session" do
    setup :create_manifest_bot
    setup :generate_do_not_disturb_session

    test "does not send messages", %{bot: bot, session: session} do
      message =
        Message.new("", bot, session)
        |> Message.respond("howdy!")

      Bot.send_message(message)

      assert MessageLog
             |> Repo.all()
             |> Enum.filter(&(&1.direction == "outgoing"))
             |> Enum.count() == 0
    end

    test "logs outgoing message as not sent", %{bot: bot, session: session} do
      message =
        Message.new("", bot, session)
        |> Message.respond("howdy!")

      Bot.send_message(message)

      [outgoing_message_log] =
        MessageLog
        |> Repo.all()
        |> Enum.filter(&(&1.direction == "not sent (do not disturb)"))

      assert outgoing_message_log.session_id == session.id
      assert outgoing_message_log.bot_id == bot.id
      assert outgoing_message_log.content == "howdy!"
    end
  end

  describe "unsubscribe keyword" do
    setup :create_manifest_bot
    setup :generate_session_for_test_channel

    test "sets session as do not disturb", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "en"})

      Message.new("UNSUBSCRIBE", bot, session)
      |> Bot.chat()

      assert Session.get(session.id).do_not_disturb
    end

    test "sets session as do not disturb for other language", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "es"})

      Message.new("DESUSCRIBIR", bot, session)
      |> Bot.chat()

      assert Session.get(session.id).do_not_disturb
    end

    test "does not set session as do not disturb for a not unsubscribe keyword", %{
      bot: bot,
      session: session
    } do
      session = session |> Session.merge(%{"language" => "en"})

      Message.new("other keyword", bot, session)
      |> Bot.chat()

      assert !Session.get(session.id).do_not_disturb
    end

    test "replies unsubscribe acknowledge message", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "en"})

      output =
        Message.new("UNSUBSCRIBE", bot, session)
        |> Bot.chat()

      assert output.reply == [
               "I won't send you any further messages"
             ]
    end

    test "replies unsubscribe acknowledge message for other language", %{
      bot: bot,
      session: session
    } do
      session = session |> Session.merge(%{"language" => "es"})

      output =
        Message.new("DESUSCRIBIR", bot, session)
        |> Bot.chat()

      assert output.reply == [
               "No te enviaré más mensajes"
             ]
    end

    test "has a reply for a not unsubscribe keyword", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "en"})

      Message.new("other keyword", bot, session)
      |> Bot.chat()

      assert MessageLog
             |> Repo.all()
             |> Enum.filter(&(&1.direction == "outgoing"))
             |> Enum.count() > 0
    end
  end

  describe "not unsubscribe keyword" do
    setup :create_manifest_bot
    setup :generate_do_not_disturb_session

    test "unsets a do not disturb session", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "en"})

      Message.new("other keyword", bot, session)
      |> Bot.chat()

      assert !Session.get(session.id).do_not_disturb
    end

    test "has a reply on a do not disturb session", %{bot: bot, session: session} do
      session = session |> Session.merge(%{"language" => "en"})

      Message.new("other keyword", bot, session)
      |> Bot.chat()

      assert MessageLog
             |> Repo.all()
             |> Enum.filter(&(&1.direction == "outgoing"))
             |> Enum.count() > 0
    end
  end

  describe "wit.ai bot" do
    setup do
      manifest =
        File.read!("test/fixtures/valid_manifest_with_wit_ai.json")
        |> Poison.decode!()

      {:ok, bot} = DB.create_bot(%{manifest: manifest})

      {:ok, bot} =
        with_mock HTTPoison,
          get: fn _, _ -> {:ok, %{status_code: 200, body: %{} |> Poison.encode!()}} end do
          BotParser.parse(bot.id, manifest)
        end

      s = Session.new({bot.id, @provider, @provider_key})
      initial_session = Repo.get(Session, s.id)

      %{bot: bot, initial_session: initial_session}
    end

    test "asks wit.ai for confidence when matching skills", %{
      bot: bot,
      initial_session: initial_session
    } do
      with_mock HTTPoison,
        post: fn _, _, _ -> {:ok, %{status_code: 200, body: %{} |> Poison.encode!()}} end,
        delete: fn _, _ -> {:ok, %{status_code: 200, body: %{} |> Poison.encode!()}} end,
        get: fn
          "https://api.wit.ai/message?v=20180815&q=what's%20your%20menu?", _ ->
            {:ok,
             %{
               status_code: 200,
               body:
                 %{
                   _text: "what's your menu?",
                   entities: %{
                     String.replace(bot.id, "-", "_") => [
                       %{confidence: 1, value: "f4c74ff9-e393-4ae1-a53e-b1e98a4c0401"}
                     ]
                   },
                   msg_id: "1LJTMxcssBF6P4Viv"
                 }
                 |> Poison.encode!()
             }}

          "https://api.wit.ai/message?v=20180815&q=Hi!", _ ->
            {:ok,
             %{
               status_code: 200,
               body:
                 %{_text: "what's your menu?", entities: %{}, msg_id: "1LJTMxcssBF6P4Viv"}
                 |> Poison.encode!()
             }}
        end do
        response = Bot.chat(Message.new("Hi!", bot, initial_session))

        assert response.reply == [
                 "Hello, I'm a Restaurant bot",
                 "I can do a number of things",
                 "I can give you information about our menu",
                 "Send UNSUBSCRIBE to stop receiving messages"
               ]

        output = Bot.chat(Message.new("what's your menu?", bot, response.session))

        assert output.reply == ["We have pizza"]
      end
    end

    test "discards wit.ai confidence when matching skill but disabled wit.ai", %{
      bot: bot,
      initial_session: initial_session
    } do

      skills = bot.skills |> Enum.map(&%{&1 | :training_sentences => nil})
      bot = Map.put(bot, :skills, skills)

      with_mock HTTPoison,
        post: fn _, _, _ -> {:ok, %{status_code: 200, body: %{} |> Poison.encode!()}} end,
        delete: fn _, _ -> {:ok, %{status_code: 200, body: %{} |> Poison.encode!()}} end,
        get: fn
          "https://api.wit.ai/message?v=20180815&q=what's%20your%20menu?", _ ->
            {:ok,
             %{
               status_code: 200,
               body:
                 %{
                   _text: "what's your menu?",
                   entities: %{
                     String.replace(bot.id, "-", "_") => [
                       %{confidence: 1, value: "f4c74ff9-e393-4ae1-a53e-b1e98a4c0401"}
                     ]
                   },
                   msg_id: "1LJTMxcssBF6P4Viv"
                 }
                 |> Poison.encode!()
             }}

          "https://api.wit.ai/message?v=20180815&q=Hi!", _ ->
            {:ok,
             %{
               status_code: 200,
               body:
                 %{_text: "what's your menu?", entities: %{}, msg_id: "1LJTMxcssBF6P4Viv"}
                 |> Poison.encode!()
             }}
        end do

        response = Bot.chat(Message.new("Hi!", bot, initial_session))

        assert response.reply == [
                 "Hello, I'm a Restaurant bot",
                 "I can do a number of things",
                 "I can give you information about our menu",
                 "Send UNSUBSCRIBE to stop receiving messages"
               ]

        output = Bot.chat(Message.new("what's your menu?", bot, response.session))

        assert output.reply == [
            "Sorry, I didn't understand that",
            "I can do a number of things",
            "I can give you information about our menu",
            "Send UNSUBSCRIBE to stop receiving messages"
          ]
 end
    end

  end

  defp create_manifest_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()

    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)
    initial_session = Session.new({bot.id, @provider, @provider_key})

    [bot: bot, initial_session: initial_session]
  end

  defp generate_session_for_test_channel(%{bot: bot}) do
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom())
    session = Session.new({bot.id, "test", "#{pid}"})

    [session: session]
  end

  defp generate_do_not_disturb_session(%{bot: bot}) do
    pid = System.unique_integer([:positive])
    Process.register(self(), "#{pid}" |> String.to_atom())

    session =
      %{Session.new({bot.id, "test", "#{pid}"}) | do_not_disturb: true}
      |> Session.save()

    [session: session]
  end
end
