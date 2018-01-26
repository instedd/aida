defmodule Aida.BotParserTest do
  use ExUnit.Case
  alias Aida.{
    Bot,
    BotParser,
    FrontDesk,
    Skill.KeywordResponder,
    Skill.LanguageDetector,
    Skill.ScheduledMessages,
    Skill.ScheduledMessages.DelayedMessage,
    Skill.ScheduledMessages.FixedTimeMessage,
    Skill.Survey,
    Skill.Survey.SelectQuestion,
    Skill.Survey.InputQuestion,
    Skill.Survey.Choice,
    Variable
  }
  alias Aida.Channel.{Facebook, WebSocket}

  @uuid "f905a698-310f-473f-b2d0-00d30ad58b0c"

  test "parse valid manifest" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.3,
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
            "en" => "We have ${food_options}",
            "es" => "Tenemos ${food_options}"
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
          schedule_type: :since_last_incoming_message,
          messages: [
            %DelayedMessage{
              delay: 1440,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last day, is there anything I can help you with?",
                "es" => "Hola! Desde ayer que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 2880,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?",
                "es" => "Hola! Hace 2 días que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 43200,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last month, is there anything I can help you with?",
                "es" => "Hola! Hace un mes que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            }
          ]
        },
        %ScheduledMessages{
          id: "happy_new_year",
          bot_id: @uuid,
          name: "Happy New Year",
          schedule_type: :fixed_time,
          messages: [
            %FixedTimeMessage{
              schedule: ~N[2018-01-01 00:00:00] |> DateTime.from_naive!("Etc/UTC"),
              message: %{
                "en" => "Happy new year!",
                "es" => "Feliz año nuevo!"
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
              relevant: Aida.Expr.parse("${age} >= 18"),
              constraint: Aida.Expr.parse(". < 100"),
              constraint_message: %{
                "en" => "Invalid temperature",
                "es" => "Temperatura inválida"
              },
              message: %{
                "en" => "At what temperature do your like red wine the best?",
                "es" => "A qué temperatura preferís tomar el vino tinto?"
                }
              },
            %SelectQuestion{
              name: "wine_grapes",
              type: :select_many,
              relevant: Aida.Expr.parse("${age} >= 18"),
              choices: [
                %Choice{
                  name: "merlot",
                  labels: %{
                    "en" => ["merlot"],
                    "es" => ["merlot"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "syrah",
                  labels: %{
                    "en" => ["syrah"],
                    "es" => ["syrah"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "malbec",
                  labels: %{
                    "en" => ["malbec"],
                    "es" => ["malbec"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "chardonnay",
                  labels: %{
                    "en" => ["chardonnay"],
                    "es" => ["chardonnay"]
                  },
                  attributes: %{
                    "type" => "white"
                  }
                }
              ],
              message: %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              },
              constraint_message: %{
                "en" => "I don't know that wine",
                "es" => "No conozco ese vino"
              },
              choice_filter: Aida.Expr.parse("type = 'red' or type = 'white'")
            },
            %InputQuestion{
              name: "picture",
              type: :image,
              message: %{
                "en" => "Can we see your home?",
                "es" => "Podemos ver tu casa?"
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
          },
          overrides: [
            %Variable.Override{
              relevant: Aida.Expr.parse("${age} > 18"),
              values: %{
                "en" => "barbecue and pasta and a exclusive selection of wines",
                "es" => "parrilla y pasta además de nuestra exclusiva selección de vinos"
              }
            }
          ]
        },
        %Variable{
          name: "title",
          values: %{
            "en" => "",
            "es" => ""
          },
          overrides: [
            %Variable.Override{
              relevant: Aida.Expr.parse("${gender} = 'male'"),
              values: %{
                "en" => "Mr.",
                "es" => "Sr."
              }
            },
            %Variable.Override{
              relevant: Aida.Expr.parse("${gender} = 'female'"),
              values: %{
                "en" => "Ms.",
                "es" => "Sra."
              }
            }
          ]
        },
        %Variable{
          name: "full_name",
          values: %{
            "en" => "${title} ${first_name} ${last_name}",
            "es" => "${title} ${first_name} ${last_name}"
          }
        }
      ],
      channels: [
        %Facebook{
          bot_id: @uuid,
          page_id: "1234567890",
          verify_token: "qwertyuiopasdfghjklzxcvbnm",
          access_token: "QWERTYUIOPASDFGHJKLZXCVBNM"
        },
        %WebSocket{
          bot_id: @uuid,
          access_token: "qwertyuiopasdfghjklzxcvbnm"
        }
      ],
      public_keys: [
        "YmIzNDYyOWEtODM0NS00NTNiLWFmODQtYWU2ZTcwMDJlNjg5",
        "YTE3ZWMyM2EtMDRhMi00ODk2LTljMDYtYTUxZDUzMTVmMDAy"
      ]
    }
  end

  test "parse valid manifest with skill relevances" do
    manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.3,
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
          id: "food_menu",
          bot_id: @uuid,
          name: "Food menu",
          keywords: %{
            "en" => ["menu", "food"],
            "es" => ["menu", "comida"]
          },
          response: %{
            "en" => "We have {food_options}",
            "es" => "Tenemos {food_options}"
          },
          relevant: Aida.Expr.parse("${age} > 18")
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
          id: "opening_hours",
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
          schedule_type: :since_last_incoming_message,
          relevant: Aida.Expr.parse("${opt_in} = true()"),
          messages: [
            %DelayedMessage{
              delay: 1440,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last day, is there anything I can help you with?",
                "es" => "Hola! Desde ayer que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 2880,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?",
                "es" => "Hola! Hace 2 días que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 43200,
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
          relevant: Aida.Expr.parse("${opt_in} != false()"),
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
              relevant: Aida.Expr.parse("${age} >= 18"),
              constraint: Aida.Expr.parse(". < 100"),
              constraint_message: %{
                "en" => "Invalid temperature",
                "es" => "Temperatura inválida"
              },
              message: %{
                "en" => "At what temperature do your like red wine the best?",
                "es" => "A qué temperatura preferís tomar el vino tinto?"
                }
              },
            %SelectQuestion{
              name: "wine_grapes",
              type: :select_many,
              relevant: Aida.Expr.parse("${age} >= 18"),
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
              },
              constraint_message: %{
                "en" => "I don't know that wine",
                "es" => "No conozco ese vino"
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
        },
        %WebSocket{
          bot_id: @uuid,
          access_token: "qwertyuiopasdfghjklzxcvbnm"
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

  test "parse manifest with invalid expression" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
      |> Map.put("skills", [
        %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Food menu",
            "relevant" => "${foo} < ...",
            "explanation" => %{
              "en" => "I can give you information about our menu"
            },
            "clarification" => %{
              "en" => "For menu options, write 'menu'"
            },
            "keywords" => %{
              "en" => ["menu","food"]
            },
            "response" => %{
              "en" => "We have ${food_options}"
            }
          }
      ])

    assert {:error, "Invalid expression: '${foo} < ...'"} == BotParser.parse(@uuid, manifest)
  end

  test "parse manifest with encrypted questions in survey" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
      |> Map.put("skills", [
        %{
          "type" => "survey",
          "id" => "food_preferences",
          "name" => "Food Preferences",
          "schedule" => "2117-12-10T01:40:13Z",
          "questions" => [
            %{
              "type" => "select_one",
              "choices" => "yes_no",
              "name" => "opt_in",
              "message" => %{
                "en" => "I would like to ask you a few questions to better cater for your food preferences. Is that ok?",
                "es" => "Me gustaría hacerte algunas preguntas para poder adecuarnos mejor a tus preferencias de comida. Puede ser?"
              }
            },
            %{
              "type" => "integer",
              "name" => "age",
              "encrypt" => true,
              "message" => %{
                "en" => "How old are you?",
                "es" => "Qué edad tenés?"
              }
            },
            %{
              "type" => "select_many",
              "name" => "wine_grapes",
              "encrypt" => true,
              "relevant" => "${age} >= 18",
              "choices" => "grapes",
              "message" => %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              }
            },
            %{
              "type" => "text",
              "name" => "request",
              "message" => %{
                "en" => "Any particular requests for your dinner?",
                "es" => "Algún pedido especial para tu cena?"
              }
            }
          ],
          "choice_lists" => [
            %{
              "name" => "yes_no",
              "choices" => [
                %{
                  "name" => "yes",
                  "labels" => %{
                    "en" => ["Yes","Sure","Ok"],
                    "es" => ["Si","OK","Dale"]
                  }
                },
                %{
                  "name" => "no",
                  "labels" =>  %{
                    "en" =>  ["No","Nope","Later"],
                    "es" =>  ["No","Luego","Nop"]
                  }
                }
              ]
            },
            %{
              "name" => "grapes",
              "choices" => [
                %{
                  "name" => "merlot",
                  "labels" => %{
                    "en" => ["merlot"],
                    "es" => ["merlot"]
                  },
                  "attributes": %{
                    "type" => "red"
                  }
                },
                %{
                  "name" => "syrah",
                  "labels" => %{
                    "en" => ["syrah"],
                    "es" => ["syrah"]
                  },
                  "attributes" => %{
                    "type" => "red"
                  }
                }
              ]
            }
          ]
        }
      ])
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    questions = (bot.skills |> hd).questions
    find_by_name = fn(questions, name) -> Enum.filter(questions, &(&1.name == name)) |> hd end

    assert find_by_name.(questions, "opt_in").encrypt != nil
    refute find_by_name.(questions, "opt_in").encrypt

    assert find_by_name.(questions, "request").encrypt != nil
    refute find_by_name.(questions, "request").encrypt

    assert find_by_name.(questions, "age").encrypt

    assert find_by_name.(questions, "wine_grapes").encrypt
  end

end
