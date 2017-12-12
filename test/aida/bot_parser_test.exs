defmodule Aida.BotParserTest do
  use ExUnit.Case
  alias Aida.{
    Bot,
    BotParser,
    FrontDesk,
    Skill.KeywordResponder,
    Skill.LanguageDetector,
    Skill.ScheduledMessages,
    Skill.Survey,
    SelectQuestion,
    InputQuestion,
    Choice,
    DelayedMessage,
    Variable
  }
  alias Aida.Channel.Facebook

  @uuid "f905a698-310f-473f-b2d0-00d30ad58b0c"

  test "parse valid manifest" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.7,
        greeting: %{
          "en" => "Hello, I'm a Restaurant bot",
          "es" => "Hola, soy un bot de Restaurant"
        },
        introduction: %{
          "en" => "I can do a number of things",
          "es" => "Puedo ayudarte con varias cosas"
        },
        not_understood: %{
          "en" => "Sorry, I didn't understand that",
          "es" => "Perdón, no entendí lo que dijiste"
        },
        clarification: %{
          "en" => "I'm not sure exactly what you need.",
          "es" => "Perdón, no estoy seguro de lo que necesitás."
        }
      },
      skills: [
        %LanguageDetector{
          explanation: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
          bot_id: @uuid,
          languages: %{
            "en" => ["english", "inglés"],
            "es" => ["español", "spanish"]
          }
        },
        %KeywordResponder{
          explanation: %{
            "en" => "I can give you information about our menu",
            "es" => "Te puedo dar información sobre nuestro menu"
          },
          clarification: %{
            "en" => "For menu options, write 'menu'",
            "es" => "Para información sobre nuestro menu, escribe 'menu'"
          },
          id: "this is a string id",
          bot_id: @uuid,
          name: "Food menu",
          keywords: %{
            "en" => ["menu", "food"],
            "es" => ["menu", "comida"]
          },
          response: %{
            "en" => "We have {food_options}",
            "es" => "Tenemos {food_options}"
          }
        },
        %KeywordResponder{
          explanation: %{
            "en" => "I can give you information about our opening hours",
            "es" => "Te puedo dar información sobre nuestro horario"
          },
          clarification: %{
            "en" => "For opening hours say 'hours'",
            "es" => "Para información sobre nuestro horario escribe 'horario'"
          },
          id: "this is a different id",
          bot_id: @uuid,
          name: "Opening hours",
          keywords: %{
            "en" => ["hours","time"],
            "es" => ["horario","hora"]
          },
          response: %{
            "en" => "We are open every day from 7pm to 11pm",
            "es" => "Abrimos todas las noches de 19 a 23"
          }
        },
        %ScheduledMessages{
          id: "inactivity_check",
          bot_id: @uuid,
          name: "Inactivity Check",
          schedule_type: "since_last_incoming_message",
          messages: [
            %DelayedMessage{
              delay: "1440",
              message: %{
                "en" => "Hey, I didn’t hear from you for the last day, is there anything I can help you with?",
                "es" => "Hola! Desde ayer que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: "2880",
              message: %{
                "en" => "Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?",
                "es" => "Hola! Hace 2 días que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: "43200",
              message: %{
                "en" => "Hey, I didn’t hear from you for the last month, is there anything I can help you with?",
                "es" => "Hola! Hace un mes que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            }
          ]
        },
        %Survey{
          id: "food_preferences",
          bot_id: @uuid,
          name: "Food Preferences",
          schedule: ~N[2117-12-10 01:40:13] |> DateTime.from_naive!("Etc/UTC"),
          questions: [
            %SelectQuestion{
              name: "opt_in",
              type: :select_one,
              choices: [
                %Choice{
                  name: "yes",
                  labels: %{
                    "en" => ["Yes", "Sure", "Ok"],
                    "es" => ["Si", "OK", "Dale"]
                  }
                },
                %Choice{
                  name: "no",
                  labels: %{
                    "en" => ["No", "Nope", "Later"],
                    "es" => ["No", "Luego", "Nop"]
                  }
                }
              ],
              message: %{
                "en" => "I would like to ask you a few questions to better cater for your food preferences. Is that ok?",
                "es" => "Me gustaría hacerte algunas preguntas para poder adecuarnos mejor a tus preferencias de comida. Puede ser?"
              }
            },
            %InputQuestion{
              name: "age",
              type: :integer,
              message: %{
                "en" => "How old are you?",
                "es" => "Qué edad tenés?"
              }
            },
            %InputQuestion{
              name: "wine_temp",
              type: :decimal,
              message: %{
                "en" => "At what temperature do your like red wine the best?",
                "es" => "A qué temperatura preferís tomar el vino tinto?"
                }
              },
            %SelectQuestion{
              name: "wine_grapes",
              type: :select_many,
              choices: [
                %Choice{
                  name: "merlot",
                  labels: %{
                    "en" => ["merlot"],
                    "es" => ["merlot"]
                  }
                },
                %Choice{
                  name: "syrah",
                  labels: %{
                    "en" => ["syrah"],
                    "es" => ["syrah"]
                  }
                },
                %Choice{
                  name: "malbec",
                  labels: %{
                    "en" => ["malbec"],
                    "es" => ["malbec"]
                  }
                }
              ],
              message: %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              }
            },
            %InputQuestion{
              name: "request",
              type: :text,
              message: %{
                "en" => "Any particular requests for your dinner?",
                "es" => "Algún pedido especial para tu cena?"
              }
            }
          ]
        }
      ],
      variables: [
        %Variable{
          name: "food_options",
          values: %{
            "en" => "barbecue and pasta",
            "es" => "parrilla y pasta"
          }
        }
      ],
      channels: [
        %Facebook{
          bot_id: @uuid,
          page_id: "1234567890",
          verify_token: "qwertyuiopasdfghjklzxcvbnm",
          access_token: "QWERTYUIOPASDFGHJKLZXCVBNM"
        }
      ]
    }
  end

  test "parse manifest with duplicated skill id" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!

    manifest = manifest
        |> Map.put("skills", [
          %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Food menu",
            "explanation" => %{
              "en" => "I can give you information about our menu",
              "es" => "Te puedo dar información sobre nuestro menu"
            },
            "clarification" => %{
              "en" => "For menu options, write 'menu'",
              "es" => "Para información sobre nuestro menu, escribe 'menu'"
            },
            "keywords" => %{
              "en" => ["menu","food"],
              "es" => ["menu","comida"]
            },
            "response" => %{
              "en" => "We have {food_options}",
              "es" => "Tenemos {food_options}"
            }
          },
          %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Opening hours",
            "explanation" => %{
              "en" => "I can give you information about our opening hours",
              "es" => "Te puedo dar información sobre nuestro horario"
            },
            "clarification" => %{
              "en" => "For opening hours say 'hours'",
              "es" => "Para información sobre nuestro horario escribe 'horario'"
            },
            "keywords" => %{
              "en" => ["hours","time"],
              "es" => ["horario","hora"]
            },
            "response" => %{
              "en" => "We are open every day from 7pm to 11pm",
              "es" => "Abrimos todas las noches de 19 a 23"
            }
          }
        ])

    assert {:error, "Duplicated skill (this is the same id)"} == BotParser.parse(@uuid, manifest)
  end

  test "parse manifest with duplicated language_detector" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!

    manifest = manifest
        |> Map.put("skills", [
          %{
            "type" => "language_detector",
            "explanation" => "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
            "languages" => %{
              "en" => ["english", "inglés"],
              "es" => ["español", "spanish"]
            }
          },
          %{
            "type" => "language_detector",
            "explanation" => "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
            "languages" => %{
              "en" => ["english", "inglés"],
              "es" => ["español", "spanish"]
            }
          }
        ])

    assert {:error, "Duplicated skill (language_detector)"} == BotParser.parse(@uuid, manifest)
  end

end
